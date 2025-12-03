import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double defaultTiffinPrice;

  @HiveField(2)
  final bool hasSetDefaultPrice;

  UserProfile({
    this.name = 'User',
    required this.defaultTiffinPrice,
    this.hasSetDefaultPrice = false,
  });

  UserProfile copyWith({
    String? name,
    double? defaultTiffinPrice,
    bool? hasSetDefaultPrice,
  }) {
    return UserProfile(
      name: name ?? this.name,
      defaultTiffinPrice: defaultTiffinPrice ?? this.defaultTiffinPrice,
      hasSetDefaultPrice: hasSetDefaultPrice ?? this.hasSetDefaultPrice,
    );
  }
}
