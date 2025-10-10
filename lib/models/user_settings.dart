import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'scene_models.dart';

part 'user_settings.g.dart';

// Model cho cài đặt ứng dụng của người dùng
@HiveType(typeId: 1)
class UserSettings {
  // Display Settings
  @HiveField(0)
  final String currentTheme;         // Theme hiện tại (theme ID)
  
  @HiveField(1)
  final String currentLanguage;      // Ngôn ngữ hiện tại (vi, en)
  
  @HiveField(2)
  final List<SceneKey> currentScenes;  // Mảng 5 phần tử: [living_room_id, garden_id, aquarium_id, painting_room_id, music_room_id]

  // Audio Settings
  @HiveField(3)
  final String bgm;                  // Background music đang chọn
  
  @HiveField(4)
  final int bgmVolume;               // 0-100
  
  @HiveField(5)
  final bool sfxEnabled;             // Bật/tắt sound effects
  
  @HiveField(6)
  final int sfxVolume;               // 0-100
  
  // Notification Settings
  @HiveField(7)
  final bool sleepReminderEnabled;   // Bật/tắt nhắc ngủ
  
  @HiveField(8)
  final int sleepReminderTimeMinutes; // Giờ nhắc ngủ lưu dưới dạng minutes (ví dụ: 22:00 = 1320)
  
  @HiveField(9)
  final bool taskReminderEnabled;    // Bật/tắt nhắc làm việc
  
  @HiveField(10)
  final int taskReminderTime;        // Nhắc trước task X phút (ví dụ: 15)

  UserSettings({
    required this.currentTheme,
    required this.currentLanguage,
    required this.currentScenes,
    required this.bgm,
    required this.bgmVolume,
    required this.sfxEnabled,
    required this.sfxVolume,
    required this.sleepReminderEnabled,
    required this.sleepReminderTimeMinutes,
    required this.taskReminderEnabled,
    required this.taskReminderTime,
  });

  // Helper getter để convert minutes sang TimeOfDay
  TimeOfDay get sleepReminderTime {
    final hours = sleepReminderTimeMinutes ~/ 60;
    final minutes = sleepReminderTimeMinutes % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  // Constructor mặc định cho cài đặt mới
  factory UserSettings.initial() {
    return UserSettings(
      // Display Settings
      currentTheme: 'pastel_blue_breeze',
      currentLanguage: 'vi', // Tiếng Việt mặc định
      currentScenes: [
        SceneKey(SceneSet.defaultSet, SceneType.livingRoom),
        SceneKey(SceneSet.defaultSet, SceneType.garden),
        SceneKey(SceneSet.defaultSet, SceneType.aquarium),
        SceneKey(SceneSet.defaultSet, SceneType.paintingRoom),
        SceneKey(SceneSet.defaultSet, SceneType.musicRoom),
      ],
      
      // Audio Settings
      bgm: 'default_bgm',
      bgmVolume: 50,
      sfxEnabled: true,
      sfxVolume: 50,
      
      // Notification Settings
      sleepReminderEnabled: false,
      sleepReminderTimeMinutes: 1320, // 22:00 = 22*60 + 0 = 1320
      taskReminderEnabled: true,
      taskReminderTime: 15, // 15 phút trước
    );
  }

  // Tạo bản sao với các thay đổi
  UserSettings copyWith({
    String? currentTheme,
    String? currentLanguage,
    List<SceneKey>? currentScenes,
    String? bgm,
    int? bgmVolume,
    bool? sfxEnabled,
    int? sfxVolume,
    bool? sleepReminderEnabled,
    int? sleepReminderTimeMinutes,
    TimeOfDay? sleepReminderTime, // Cho phép truyền TimeOfDay
    bool? taskReminderEnabled,
    int? taskReminderTime,
  }) {
    // Nếu truyền TimeOfDay, convert sang minutes
    int? finalSleepMinutes = sleepReminderTimeMinutes;
    if (sleepReminderTime != null) {
      finalSleepMinutes = sleepReminderTime.hour * 60 + sleepReminderTime.minute;
    }

    return UserSettings(
      currentTheme: currentTheme ?? this.currentTheme,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      currentScenes: currentScenes ?? List<SceneKey>.from(this.currentScenes),
      bgm: bgm ?? this.bgm,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      sleepReminderEnabled: sleepReminderEnabled ?? this.sleepReminderEnabled,
      sleepReminderTimeMinutes: finalSleepMinutes ?? this.sleepReminderTimeMinutes,
      taskReminderEnabled: taskReminderEnabled ?? this.taskReminderEnabled,
      taskReminderTime: taskReminderTime ?? this.taskReminderTime,
    );
  }
}