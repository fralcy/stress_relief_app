// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepLogAdapter extends TypeAdapter<SleepLog> {
  @override
  final int typeId = 21;

  @override
  SleepLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepLog(
      date: fields[0] as DateTime,
      bedtimeMinutes: fields[1] as int?,
      wakeTimeMinutes: fields[2] as int?,
      quality: fields[3] as int?,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SleepLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.bedtimeMinutes)
      ..writeByte(2)
      ..write(obj.wakeTimeMinutes)
      ..writeByte(3)
      ..write(obj.quality)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
