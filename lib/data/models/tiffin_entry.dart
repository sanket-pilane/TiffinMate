import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'tiffin_entry.g.dart';

@HiveType(typeId: 1)
class TiffinEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String menu;

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  final String lastEditedBy; // 'user' or 'admin'

  @HiveField(7)
  final String status; // 'confirmed', 'pending_approval', 'disputed', 'skipped'

  @HiveField(8)
  final bool adminModified;

  @HiveField(9)
  final Map<String, dynamic>? originalEntry;

  @HiveField(10)
  final DateTime? updatedAt;

  @HiveField(11)
  final DateTime? createdAt;

  @HiveField(12)
  final String syncStatus; // 'synced', 'pendingUpload', 'conflict'

  TiffinEntry({
    String? id,
    required this.date,
    required this.type,
    required this.price,
    this.menu = '',
    this.isSynced = false,
    this.lastEditedBy = 'user',
    this.status = 'confirmed',
    this.adminModified = false,
    this.originalEntry,
    this.updatedAt,
    this.createdAt,
    this.syncStatus = 'synced',
  }) : id = id ?? const Uuid().v4();

  TiffinEntry copyWith({
    String? id,
    DateTime? date,
    String? type,
    double? price,
    String? menu,
    bool? isSynced,
    String? lastEditedBy,
    String? status,
    bool? adminModified,
    Map<String, dynamic>? originalEntry,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return TiffinEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      price: price ?? this.price,
      menu: menu ?? this.menu,
      isSynced: isSynced ?? this.isSynced,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      status: status ?? this.status,
      adminModified: adminModified ?? this.adminModified,
      originalEntry: originalEntry ?? this.originalEntry,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // --- NEW: Firestore Helpers ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'price': price,
      'menu': menu,
      'lastEditedBy': lastEditedBy,
      'status': status,
      'adminModified': adminModified,
      'originalEntry': originalEntry,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory TiffinEntry.fromMap(Map<String, dynamic> map) {
    return TiffinEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      price: (map['price'] as num).toDouble(),
      menu: map['menu'] ?? '',
      isSynced: true, // If coming from cloud, it is synced
      lastEditedBy: map['lastEditedBy'] ?? 'user',
      status: map['status'] ?? 'confirmed',
      adminModified: map['adminModified'] ?? false,
      originalEntry: map['originalEntry'] != null
          ? Map<String, dynamic>.from(map['originalEntry'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      syncStatus: 'synced',
    );
  }
}
