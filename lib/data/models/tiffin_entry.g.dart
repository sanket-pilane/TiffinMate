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
    );
  }

  @override
  void write(BinaryWriter writer, TiffinEntry obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.isSynced);
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
