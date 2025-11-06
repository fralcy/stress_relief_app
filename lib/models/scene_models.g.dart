// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SceneKeyAdapter extends TypeAdapter<SceneKey> {
  @override
  final int typeId = 10;

  @override
  SceneKey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SceneKey(
      fields[0] as SceneSet,
      fields[1] as SceneType,
    );
  }

  @override
  void write(BinaryWriter writer, SceneKey obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sceneSet)
      ..writeByte(1)
      ..write(obj.sceneType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneKeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SceneSetAdapter extends TypeAdapter<SceneSet> {
  @override
  final int typeId = 8;

  @override
  SceneSet read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SceneSet.defaultSet;
      case 1:
        return SceneSet.japanese;
      case 2:
        return SceneSet.beach;
      case 3:
        return SceneSet.winter;
      case 4:
        return SceneSet.forest;
      default:
        return SceneSet.defaultSet;
    }
  }

  @override
  void write(BinaryWriter writer, SceneSet obj) {
    switch (obj) {
      case SceneSet.defaultSet:
        writer.writeByte(0);
        break;
      case SceneSet.japanese:
        writer.writeByte(1);
        break;
      case SceneSet.beach:
        writer.writeByte(2);
        break;
      case SceneSet.winter:
        writer.writeByte(3);
        break;
      case SceneSet.forest:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SceneTypeAdapter extends TypeAdapter<SceneType> {
  @override
  final int typeId = 9;

  @override
  SceneType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SceneType.livingRoom;
      case 1:
        return SceneType.garden;
      case 2:
        return SceneType.aquarium;
      case 3:
        return SceneType.paintingRoom;
      case 4:
        return SceneType.musicRoom;
      default:
        return SceneType.livingRoom;
    }
  }

  @override
  void write(BinaryWriter writer, SceneType obj) {
    switch (obj) {
      case SceneType.livingRoom:
        writer.writeByte(0);
        break;
      case SceneType.garden:
        writer.writeByte(1);
        break;
      case SceneType.aquarium:
        writer.writeByte(2);
        break;
      case SceneType.paintingRoom:
        writer.writeByte(3);
        break;
      case SceneType.musicRoom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MascotExpressionAdapter extends TypeAdapter<MascotExpression> {
  @override
  final int typeId = 11;

  @override
  MascotExpression read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MascotExpression.idle;
      case 1:
        return MascotExpression.happy;
      case 2:
        return MascotExpression.calm;
      case 3:
        return MascotExpression.sad;
      case 4:
        return MascotExpression.sleepy;
      case 5:
        return MascotExpression.surprised;
      default:
        return MascotExpression.idle;
    }
  }

  @override
  void write(BinaryWriter writer, MascotExpression obj) {
    switch (obj) {
      case MascotExpression.idle:
        writer.writeByte(0);
        break;
      case MascotExpression.happy:
        writer.writeByte(1);
        break;
      case MascotExpression.calm:
        writer.writeByte(2);
        break;
      case MascotExpression.sad:
        writer.writeByte(3);
        break;
      case MascotExpression.sleepy:
        writer.writeByte(4);
        break;
      case MascotExpression.surprised:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MascotExpressionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
