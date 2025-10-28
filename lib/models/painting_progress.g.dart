// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'painting_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaintingAdapter extends TypeAdapter<Painting> {
  @override
  final int typeId = 14;

  @override
  Painting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Painting(
      name: fields[0] as String,
      createdAt: fields[1] as DateTime,
      pixels: (fields[2] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Painting obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.pixels);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaintingProgressAdapter extends TypeAdapter<PaintingProgress> {
  @override
  final int typeId = 6;

  @override
  PaintingProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaintingProgress(
      savedPaintings: (fields[0] as List?)?.cast<Painting>(),
      selected: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PaintingProgress obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.savedPaintings)
      ..writeByte(1)
      ..write(obj.selected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintingProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
