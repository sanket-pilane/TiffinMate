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

  @HiveField(3)
  final String role; // 'user', 'admin'

  @HiveField(4)
  final String id;

  @HiveField(5)
  final String? vendorId;

  UserProfile({
    this.name = 'User',
    required this.defaultTiffinPrice,
    this.hasSetDefaultPrice = false,
    this.role = 'user',
    this.id = '',
    this.vendorId,
  });

  UserProfile copyWith({
    String? name,
    double? defaultTiffinPrice,
    bool? hasSetDefaultPrice,
    String? role,
    String? id,
    String? vendorId,
  }) {
    return UserProfile(
      name: name ?? this.name,
      defaultTiffinPrice: defaultTiffinPrice ?? this.defaultTiffinPrice,
      hasSetDefaultPrice: hasSetDefaultPrice ?? this.hasSetDefaultPrice,
      role: role ?? this.role,
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}
