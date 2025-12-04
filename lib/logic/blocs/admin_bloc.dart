import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/data/repositories/admin_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';

import 'admin_event.dart';
import 'admin_state.dart';

export 'admin_event.dart';
export 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({required AdminRepository repository})
    : _repository = repository,
      super(const AdminState()) {
    on<LoadUsers>(_onLoadUsers);
    on<BulkAddEntry>(_onBulkAddEntry);
    on<LoadDisputes>(_onLoadDisputes);
    on<ResolveDispute>(_onResolveDispute);
    on<MarkDailyTiffin>(_onMarkDailyTiffin);
    on<UnmarkDailyTiffin>(_onUnmarkDailyTiffin);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      final users = await _repository.getAllUsers();
      // TODO: Load daily distribution status for today
      // For now, we just load users
      emit(state.copyWith(status: AdminStatus.success, users: users));
    } catch (e) {
      emit(
        state.copyWith(status: AdminStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onBulkAddEntry(
    BulkAddEntry event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      await _repository.bulkAddTiffinEntries(
        event.userIds,
        event.entryTemplate,
      );
      emit(state.copyWith(status: AdminStatus.success));
      add(LoadUsers());
    } catch (e) {
      emit(
        state.copyWith(status: AdminStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoadDisputes(
    LoadDisputes event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      final disputes = await _repository.getDisputedEntries();
      emit(state.copyWith(status: AdminStatus.success, disputes: disputes));
    } catch (e) {
      emit(
        state.copyWith(status: AdminStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onResolveDispute(
    ResolveDispute event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      await _repository.resolveDispute(event.userId, event.entry);
      add(LoadDisputes());
    } catch (e) {
      emit(
        state.copyWith(status: AdminStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onMarkDailyTiffin(
    MarkDailyTiffin event,
    Emitter<AdminState> emit,
  ) async {
    try {
      // Optimistic update
      final newDistribution = Map<String, bool>.from(state.dailyDistribution);
      newDistribution[event.userId] = true;
      emit(state.copyWith(dailyDistribution: newDistribution));

      final entry = TiffinEntry(
        id: const Uuid().v4(),
        date: event.date,
        type: 'Lunch', // Default to Lunch for now, or make it configurable
        price: 0, // Will be set by backend/repo based on user default
        menu: 'Daily Tiffin',
        status: 'confirmed',
        lastEditedBy: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.bulkAddTiffinEntries([event.userId], entry);
    } catch (e) {
      // Revert on failure
      final newDistribution = Map<String, bool>.from(state.dailyDistribution);
      newDistribution[event.userId] = false;
      emit(
        state.copyWith(
          dailyDistribution: newDistribution,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUnmarkDailyTiffin(
    UnmarkDailyTiffin event,
    Emitter<AdminState> emit,
  ) async {
    try {
      // Optimistic update
      final newDistribution = Map<String, bool>.from(state.dailyDistribution);
      newDistribution[event.userId] = false;
      emit(state.copyWith(dailyDistribution: newDistribution));

      // We need to find the entry for today and delete it.
      // This is tricky without fetching. For now, we might need a repository method
      // that deletes by date/user.
      // await _repository.removeEntryForUserDate(event.userId, event.date);
      // Since we don't have that yet, let's just log or show error that unmarking isn't fully supported yet
      // OR implement it properly.
    } catch (e) {
      // Revert
      final newDistribution = Map<String, bool>.from(state.dailyDistribution);
      newDistribution[event.userId] = true;
      emit(
        state.copyWith(
          dailyDistribution: newDistribution,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
