// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_diary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionDiaryAdapter extends TypeAdapter<EmotionDiary> {
  @override
  final int typeId = 3;

  @override
  EmotionDiary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionDiary(
      date: fields[0] as DateTime,
      q1: fields[1] as int,
      q2: fields[2] as int,
      q3: fields[3] as int,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmotionDiary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.q1)
      ..writeByte(2)
      ..write(obj.q2)
      ..writeByte(3)
      ..write(obj.q3)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionDiaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
