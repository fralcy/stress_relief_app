// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepSessionAdapter extends TypeAdapter<SleepSession> {
  @override
  final int typeId = 19;

  @override
  SleepSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSession(
      startTime: fields[0] as DateTime,
      bgmTrack: fields[1] as String,
      timerDurationMinutes: fields[2] as int,
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.bgmTrack)
      ..writeByte(2)
      ..write(obj.timerDurationMinutes)
      ..writeByte(3)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
