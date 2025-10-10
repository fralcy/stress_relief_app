// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 1;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      currentTheme: fields[0] as String,
      currentLanguage: fields[1] as String,
      currentScenes: (fields[2] as List).cast<SceneKey>(),
      bgm: fields[3] as String,
      bgmVolume: fields[4] as int,
      sfxEnabled: fields[5] as bool,
      sfxVolume: fields[6] as int,
      sleepReminderEnabled: fields[7] as bool,
      sleepReminderTimeMinutes: fields[8] as int,
      taskReminderEnabled: fields[9] as bool,
      taskReminderTime: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.currentTheme)
      ..writeByte(1)
      ..write(obj.currentLanguage)
      ..writeByte(2)
      ..write(obj.currentScenes)
      ..writeByte(3)
      ..write(obj.bgm)
      ..writeByte(4)
      ..write(obj.bgmVolume)
      ..writeByte(5)
      ..write(obj.sfxEnabled)
      ..writeByte(6)
      ..write(obj.sfxVolume)
      ..writeByte(7)
      ..write(obj.sleepReminderEnabled)
      ..writeByte(8)
      ..write(obj.sleepReminderTimeMinutes)
      ..writeByte(9)
      ..write(obj.taskReminderEnabled)
      ..writeByte(10)
      ..write(obj.taskReminderTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
