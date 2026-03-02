// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementProgressAdapter extends TypeAdapter<AchievementProgress> {
  @override
  final int typeId = 22;

  @override
  AchievementProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementProgress(
      unlockedIds: (fields[0] as List).cast<String>(),
      counters: (fields[1] as Map).cast<String, int>(),
      unlockedAt: (fields[2] as Map).cast<String, int>(),
      newlyUnlocked: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AchievementProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.unlockedIds)
      ..writeByte(1)
      ..write(obj.counters)
      ..writeByte(2)
      ..write(obj.unlockedAt)
      ..writeByte(3)
      ..write(obj.newlyUnlocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
