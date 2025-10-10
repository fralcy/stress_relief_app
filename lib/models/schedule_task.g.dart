// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleTaskAdapter extends TypeAdapter<ScheduleTask> {
  @override
  final int typeId = 2;

  @override
  ScheduleTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleTask(
      title: fields[0] as String,
      startTimeMinutes: fields[1] as int,
      endTimeMinutes: fields[2] as int,
      isCompleted: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleTask obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startTimeMinutes)
      ..writeByte(2)
      ..write(obj.endTimeMinutes)
      ..writeByte(3)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
