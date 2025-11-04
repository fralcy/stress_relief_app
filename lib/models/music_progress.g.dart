// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 16;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      pitch: fields[0] as String,
      startTimeMilliseconds: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.pitch)
      ..writeByte(1)
      ..write(obj.startTimeMilliseconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MusicTrackAdapter extends TypeAdapter<MusicTrack> {
  @override
  final int typeId = 17;

  @override
  MusicTrack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MusicTrack(
      name: fields[0] as String,
      createdAt: fields[1] as DateTime,
      tracks: (fields[2] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as Instrument, (v as List).cast<Note>())),
    );
  }

  @override
  void write(BinaryWriter writer, MusicTrack obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.tracks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicTrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MusicProgressAdapter extends TypeAdapter<MusicProgress> {
  @override
  final int typeId = 7;

  @override
  MusicProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MusicProgress(
      savedTracks: (fields[0] as List).cast<MusicTrack>(),
      selected: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MusicProgress obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.savedTracks)
      ..writeByte(1)
      ..write(obj.selected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstrumentAdapter extends TypeAdapter<Instrument> {
  @override
  final int typeId = 15;

  @override
  Instrument read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Instrument.key;
      case 1:
        return Instrument.string;
      case 2:
        return Instrument.synth;
      case 3:
        return Instrument.bass;
      case 4:
        return Instrument.drum;
      default:
        return Instrument.key;
    }
  }

  @override
  void write(BinaryWriter writer, Instrument obj) {
    switch (obj) {
      case Instrument.key:
        writer.writeByte(0);
        break;
      case Instrument.string:
        writer.writeByte(1);
        break;
      case Instrument.synth:
        writer.writeByte(2);
        break;
      case Instrument.bass:
        writer.writeByte(3);
        break;
      case Instrument.drum:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
