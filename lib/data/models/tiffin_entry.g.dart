// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiffin_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TiffinEntryAdapter extends TypeAdapter<TiffinEntry> {
  @override
  final int typeId = 1;

  @override
  TiffinEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TiffinEntry(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      type: fields[2] as String,
      price: fields[3] as double,
      menu: fields[4] as String,
      isSynced: fields[5] as bool,
      lastEditedBy: fields[6] as String,
      status: fields[7] as String,
      adminModified: fields[8] as bool,
      originalEntry: (fields[9] as Map?)?.cast<String, dynamic>(),
      updatedAt: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime?,
      syncStatus: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TiffinEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.menu)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.lastEditedBy)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.adminModified)
      ..writeByte(9)
      ..write(obj.originalEntry)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TiffinEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
