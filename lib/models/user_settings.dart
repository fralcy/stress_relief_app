import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';

// Model cho cài đặt ứng dụng của người dùng
class UserSettings {
  // Display Settings
  final String currentTheme;         // Theme hiện tại (theme ID)
  final String currentLanguage;      // Ngôn ngữ hiện tại (vi, en)
  final List<SceneKey> currentScenes;  // Mảng 5 phần tử: [living_room_id, garden_id, aquarium_id, painting_room_id, music_room_id]

  // Audio Settings
  final String bgm;                  // Background music đang chọn
  final int bgmVolume;               // 0-100
  final bool sfxEnabled;             // Bật/tắt sound effects
  final int sfxVolume;               // 0-100
  
  // Notification Settings
  final bool sleepReminderEnabled;   // Bật/tắt nhắc ngủ
  final TimeOfDay sleepReminderTime; // Giờ nhắc ngủ (ví dụ: 22:00)
  final bool taskReminderEnabled;    // Bật/tắt nhắc làm việc
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
    required this.sleepReminderTime,
    required this.taskReminderEnabled,
    required this.taskReminderTime,
  });

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
      sleepReminderTime: const TimeOfDay(hour: 22, minute: 0), // 22:00
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
    TimeOfDay? sleepReminderTime,
    bool? taskReminderEnabled,
    int? taskReminderTime,
  }) {
    return UserSettings(
      currentTheme: currentTheme ?? this.currentTheme,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      currentScenes: currentScenes ?? List<SceneKey>.from(this.currentScenes),
      bgm: bgm ?? this.bgm,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      sleepReminderEnabled: sleepReminderEnabled ?? this.sleepReminderEnabled,
      sleepReminderTime: sleepReminderTime ?? this.sleepReminderTime,
      taskReminderEnabled: taskReminderEnabled ?? this.taskReminderEnabled,
      taskReminderTime: taskReminderTime ?? this.taskReminderTime,
    );
  }
}