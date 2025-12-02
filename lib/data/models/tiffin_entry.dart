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

  TiffinEntry({
    String? id,
    required this.date,
    required this.type,
    required this.price,
    this.menu = '',
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  TiffinEntry copyWith({
    String? id,
    DateTime? date,
    String? type,
    double? price,
    String? menu,
    bool? isSynced,
  }) {
    return TiffinEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      price: price ?? this.price,
      menu: menu ?? this.menu,
      isSynced: isSynced ?? this.isSynced,
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
    );
  }
}
