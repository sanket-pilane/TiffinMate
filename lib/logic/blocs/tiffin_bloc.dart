import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';

import 'tiffin_event.dart';
import 'tiffin_state.dart';

class TiffinBloc extends Bloc<TiffinEvent, TiffinState> {
  final TiffinRepository _repository;

  TiffinBloc({required TiffinRepository repository})
    : _repository = repository,
      super(const TiffinState()) {
    on<LoadTiffins>(_onLoadTiffins);
    on<AddTiffinEntryEvent>(_onAddTiffinEntry);
    on<DeleteTiffinEntryEvent>(_onDeleteTiffinEntry);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
  }

  Future<void> _onLoadTiffins(
    LoadTiffins event,
    Emitter<TiffinState> emit,
  ) async {
    emit(state.copyWith(status: TiffinStatus.loading));
    try {
      final tiffins = await _repository.getAllLocalTiffins();
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
      await _repository.addTiffinEntry(event.entry);
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
