import 'package:equatable/equatable.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

enum TiffinStatus { initial, loading, success, failure }

class TiffinState extends Equatable {
  final TiffinStatus status;
  final List<TiffinEntry> tiffins;
  final UserProfile? userProfile;
  final String? errorMessage;

  const TiffinState({
    this.status = TiffinStatus.initial,
    this.tiffins = const [],
    this.userProfile,
    this.errorMessage,
  });

  TiffinState copyWith({
    TiffinStatus? status,
    List<TiffinEntry>? tiffins,
    UserProfile? userProfile,
    String? errorMessage,
  }) {
    return TiffinState(
      status: status ?? this.status,
      tiffins: tiffins ?? this.tiffins,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tiffins, userProfile, errorMessage];
}
