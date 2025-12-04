import 'package:hive/hive.dart';

part 'audit_log.g.dart';

@HiveType(typeId: 2)
class AuditLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String adminId;

  @HiveField(2)
  final String actionType;

  @HiveField(3)
  final String entryId;

  @HiveField(4)
  final String targetUserId;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final Map<String, dynamic> meta;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.actionType,
    required this.entryId,
    required this.targetUserId,
    required this.timestamp,
    this.meta = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'actionType': actionType,
      'entryId': entryId,
      'targetUserId': targetUserId,
      'timestamp': timestamp.toIso8601String(),
      'meta': meta,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      adminId: map['adminId'],
      actionType: map['actionType'],
      entryId: map['entryId'],
      targetUserId: map['targetUserId'],
      timestamp: DateTime.parse(map['timestamp']),
      meta: Map<String, dynamic>.from(map['meta'] ?? {}),
    );
  }
}
