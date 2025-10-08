import 'package:flutter/material.dart';
// Model cho cài đặt ứng dụng của người dùng
class UserSettings {
  // Display Settings
  final String currentTheme;         // Theme hiện tại
  final List<String> currentScenes;  // Mảng 5 phần tử: [living_room_id, garden_id, aquarium_id, painting_room_id, music_room_id]

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
      currentTheme: 'default',
      currentScenes: [
        'living_room_default',
        'garden_default', 
        'aquarium_default',
        'painting_room_default',
        'music_room_default'
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
    List<String>? currentScenes,
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
      currentScenes: currentScenes ?? List<String>.from(this.currentScenes),
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