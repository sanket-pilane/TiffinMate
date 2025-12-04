import 'package:equatable/equatable.dart';
import 'package:tiffin_mate/data/models/dispute_item.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

enum AdminStatus { initial, loading, success, failure }

class AdminState extends Equatable {
  final AdminStatus status;
  final List<UserProfile> users;
  final List<DisputeItem> disputes;
  final String? errorMessage;
  final Map<String, bool> dailyDistribution; // userId -> delivered status

  const AdminState({
    this.status = AdminStatus.initial,
    this.users = const [],
    this.disputes = const [],
    this.errorMessage,
    this.dailyDistribution = const {},
  });

  AdminState copyWith({
    AdminStatus? status,
    List<UserProfile>? users,
    List<DisputeItem>? disputes,
    String? errorMessage,
    Map<String, bool>? dailyDistribution,
  }) {
    return AdminState(
      status: status ?? this.status,
      users: users ?? this.users,
      disputes: disputes ?? this.disputes,
      errorMessage: errorMessage ?? this.errorMessage,
      dailyDistribution: dailyDistribution ?? this.dailyDistribution,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    disputes,
    errorMessage,
    dailyDistribution,
  ];
}
