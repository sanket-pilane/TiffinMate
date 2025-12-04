import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';

import 'tiffin_event.dart';
import 'tiffin_state.dart';

import 'package:tiffin_mate/data/models/audit_log.dart';
import 'package:tiffin_mate/data/repositories/audit_repository.dart';
import 'package:uuid/uuid.dart';

class TiffinBloc extends Bloc<TiffinEvent, TiffinState> {
  final TiffinRepository _repository;
  final AuditRepository? _auditRepository;

  TiffinBloc({
    required TiffinRepository repository,
    AuditRepository? auditRepository,
  }) : _repository = repository,
       _auditRepository = auditRepository,
       super(const TiffinState()) {
    on<LoadTiffins>(_onLoadTiffins);
    on<AddTiffinEntryEvent>(_onAddTiffinEntry);
    on<DeleteTiffinEntryEvent>(_onDeleteTiffinEntry);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
    on<ConfirmTiffinEntryEvent>(_onConfirmTiffinEntry);
    on<DisputeTiffinEntryEvent>(_onDisputeTiffinEntry);
  }

  Future<void> _onLoadTiffins(
    LoadTiffins event,
    Emitter<TiffinState> emit,
  ) async {
    emit(state.copyWith(status: TiffinStatus.loading));
    try {
      // Ensure user data is initialized (boxes opened)
      await _repository.initUserData();

      final tiffins = await _repository.getAllLocalTiffins();
      // Sync profile from cloud to ensure role is up to date
      await _repository.syncUserProfileFromCloud();
      final profile = await _repository.getUserProfile();
      emit(
        state.copyWith(
          status: TiffinStatus.success,
          tiffins: tiffins,
          userProfile: profile,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddTiffinEntry(
    AddTiffinEntryEvent event,
    Emitter<TiffinState> emit,
  ) async {
    try {
      // When user adds entry, it is confirmed by default and lastEditedBy user
      final entry = event.entry.copyWith(
        lastEditedBy: 'user',
        status: 'confirmed',
        updatedAt: DateTime.now(),
      );
      await _repository.addTiffinEntry(entry);
      add(LoadTiffins());
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConfirmTiffinEntry(
    ConfirmTiffinEntryEvent event,
    Emitter<TiffinState> emit,
  ) async {
    try {
      final entry = event.entry.copyWith(
        status: 'confirmed',
        lastEditedBy: 'user',
        updatedAt: DateTime.now(),
      );
      await _repository.addTiffinEntry(entry);

      if (_auditRepository != null) {
        final auditLog = AuditLog(
          id: const Uuid().v4(),
          adminId: 'user',
          actionType: 'user_confirmed',
          entryId: entry.id,
          targetUserId: 'current_user',
          timestamp: DateTime.now(),
          meta: entry.toMap(),
        );
        await _auditRepository.logAction(auditLog);
      }

      add(LoadTiffins());
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDisputeTiffinEntry(
    DisputeTiffinEntryEvent event,
    Emitter<TiffinState> emit,
  ) async {
    try {
      final entry = event.entry.copyWith(
        status: 'disputed',
        lastEditedBy: 'user',
        updatedAt: DateTime.now(),
        // We could store the dispute reason in meta or a separate field if needed
        // For now, status 'disputed' is enough to flag it
      );
      await _repository.addTiffinEntry(entry);

      if (_auditRepository != null) {
        final auditLog = AuditLog(
          id: const Uuid().v4(),
          adminId: 'user',
          actionType: 'user_disputed',
          entryId: entry.id,
          targetUserId: 'current_user',
          timestamp: DateTime.now(),
          meta: {...entry.toMap(), 'reason': event.reason},
        );
        await _auditRepository.logAction(auditLog);
      }

      add(LoadTiffins());
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteTiffinEntry(
    DeleteTiffinEntryEvent event,
    Emitter<TiffinState> emit,
  ) async {
    try {
      await _repository.deleteTiffinEntry(event.id);
      add(LoadTiffins());
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<TiffinState> emit,
  ) async {
    try {
      await _repository.saveUserProfile(event.profile);
      add(LoadTiffins());
    } catch (e) {
      emit(
        state.copyWith(
          status: TiffinStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
