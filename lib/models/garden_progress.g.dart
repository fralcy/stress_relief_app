// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'garden_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlantCellAdapter extends TypeAdapter<PlantCell> {
  @override
  final int typeId = 12;

  @override
  PlantCell read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlantCell(
      plantType: fields[0] as String?,
      growthStage: fields[1] as int,
      lastWatered: fields[2] as DateTime,
      needsWater: fields[3] as bool,
      hasPest: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlantCell obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.plantType)
      ..writeByte(1)
      ..write(obj.growthStage)
      ..writeByte(2)
      ..write(obj.lastWatered)
      ..writeByte(3)
      ..write(obj.needsWater)
      ..writeByte(4)
      ..write(obj.hasPest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantCellAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GardenProgressAdapter extends TypeAdapter<GardenProgress> {
  @override
  final int typeId = 4;

  @override
  GardenProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GardenProgress(
      plots: (fields[0] as List?)
          ?.map((dynamic e) => (e as List).cast<PlantCell>())
          ?.toList(),
      inventory: (fields[1] as Map).cast<String, int>(),
      earnings: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GardenProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.plots)
      ..writeByte(1)
      ..write(obj.inventory)
      ..writeByte(2)
      ..write(obj.earnings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GardenProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
