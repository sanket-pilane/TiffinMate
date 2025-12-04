import 'package:equatable/equatable.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends AdminEvent {}

class BulkAddEntry extends AdminEvent {
  final List<String> userIds;
  final TiffinEntry entryTemplate;

  const BulkAddEntry({required this.userIds, required this.entryTemplate});

  @override
  List<Object?> get props => [userIds, entryTemplate];
}

class LoadDisputes extends AdminEvent {}

class ResolveDispute extends AdminEvent {
  final String userId;
  final TiffinEntry entry;

  const ResolveDispute({required this.userId, required this.entry});

  @override
  List<Object?> get props => [userId, entry];
}

class MarkDailyTiffin extends AdminEvent {
  final String userId;
  final DateTime date;

  const MarkDailyTiffin({required this.userId, required this.date});

  @override
  List<Object?> get props => [userId, date];
}

class UnmarkDailyTiffin extends AdminEvent {
  final String userId;
  final DateTime date;

  const UnmarkDailyTiffin({required this.userId, required this.date});

  @override
  List<Object?> get props => [userId, date];
}
