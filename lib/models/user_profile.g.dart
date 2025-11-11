// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      name: fields[3] as String,
      mascotName: fields[4] as String,
      createdAt: fields[5] as DateTime,
      lastSyncedAt: fields[6] as DateTime,
      lastUpdatedAt: fields[11] as DateTime,
      unlockedScenes: (fields[7] as Map).cast<SceneKey, bool>(),
      currentPoints: fields[8] as int,
      totalPoints: fields[9] as int,
      lastPointsClaimDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.mascotName)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastSyncedAt)
      ..writeByte(11)
      ..write(obj.lastUpdatedAt)
      ..writeByte(7)
      ..write(obj.unlockedScenes)
      ..writeByte(8)
      ..write(obj.currentPoints)
      ..writeByte(9)
      ..write(obj.totalPoints)
      ..writeByte(10)
      ..write(obj.lastPointsClaimDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
