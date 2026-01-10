// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breathing_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreathingSessionAdapter extends TypeAdapter<BreathingSession> {
  @override
  final int typeId = 18;

  @override
  BreathingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingSession(
      date: fields[0] as DateTime,
      exerciseType: fields[1] as String,
      durationSeconds: fields[2] as int,
      cyclesCompleted: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.exerciseType)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.cyclesCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
