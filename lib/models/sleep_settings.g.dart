// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepSettingsAdapter extends TypeAdapter<SleepSettings> {
  @override
  final int typeId = 20;

  @override
  SleepSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSettings(
      bedtimeMinutes: fields[0] as int?,
      wakeTimeMinutes: fields[1] as int?,
      defaultTimerMinutes: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.bedtimeMinutes)
      ..writeByte(1)
      ..write(obj.wakeTimeMinutes)
      ..writeByte(2)
      ..write(obj.defaultTimerMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
