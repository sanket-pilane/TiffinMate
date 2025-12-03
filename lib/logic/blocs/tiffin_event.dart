import 'package:equatable/equatable.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

abstract class TiffinEvent extends Equatable {
  const TiffinEvent();

  @override
  List<Object> get props => [];
}

class LoadTiffins extends TiffinEvent {}

class AddTiffinEntryEvent extends TiffinEvent {
  final TiffinEntry entry;

  const AddTiffinEntryEvent(this.entry);

  @override
  List<Object> get props => [entry];
}

class DeleteTiffinEntryEvent extends TiffinEvent {
  final String id;

  const DeleteTiffinEntryEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UpdateUserProfileEvent extends TiffinEvent {
  final UserProfile profile;

  const UpdateUserProfileEvent(this.profile);

  @override
  List<Object> get props => [profile];
}
