// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aquarium_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FishAdapter extends TypeAdapter<Fish> {
  @override
  final int typeId = 13;

  @override
  Fish read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Fish(
      type: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Fish obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AquariumProgressAdapter extends TypeAdapter<AquariumProgress> {
  @override
  final int typeId = 5;

  @override
  AquariumProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AquariumProgress(
      fishes: (fields[0] as List).cast<Fish>(),
      lastFed: fields[1] as DateTime,
      earnings: fields[2] as int,
      lastClaimed: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AquariumProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fishes)
      ..writeByte(1)
      ..write(obj.lastFed)
      ..writeByte(2)
      ..write(obj.earnings)
      ..writeByte(3)
      ..write(obj.lastClaimed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AquariumProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
