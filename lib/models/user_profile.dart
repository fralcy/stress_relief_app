import 'package:hive/hive.dart';
import 'scene_models.dart';

part 'user_profile.g.dart';

// Model cho thông tin cá nhân và cài đặt người dùng
@HiveType(typeId: 0)
class UserProfile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;              // Username unique (để login)
  
  @HiveField(2)
  final String email;                 // Email (để login + recovery)
  
  @HiveField(3)
  final String name;                  // Tên người dùng
  
  @HiveField(4)
  final String mascotName;            // Tên linh vật
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime lastSyncedAt;        // Timestamp lần sync gần nhất
  
  // Progress
  @HiveField(7)
  final Map<SceneKey, bool> unlockedScenes;  // Các cảnh đã mở khóa
  
  // Points
  @HiveField(8)
  final int currentPoints;            // Điểm hiện có để tiêu
  
  @HiveField(9)
  final int totalPoints;              // Tổng điểm tích lũy (lifetime)

  @HiveField(10)
  final DateTime? lastPointsClaimDate;  // Ngày cuối cùng nhận điểm thưởng

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.mascotName,
    required this.createdAt,
    required this.lastSyncedAt,
    required this.unlockedScenes,
    required this.currentPoints,
    required this.totalPoints,
    this.lastPointsClaimDate,
  });
  
  // Constructor mặc định cho người dùng mới
  factory UserProfile.initial({
    required String id,
    required String username,
    required String email,
    required String name,
    String mascotName = 'Cat',
  }) {
    return UserProfile(
      id: id,
      username: username,
      email: email,
      name: name,
      mascotName: mascotName,
      createdAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
      unlockedScenes: <SceneKey, bool>{
        SceneKey(SceneSet.defaultSet, SceneType.livingRoom): true,
        SceneKey(SceneSet.defaultSet, SceneType.garden): true,
        SceneKey(SceneSet.defaultSet, SceneType.aquarium): true,
        SceneKey(SceneSet.defaultSet, SceneType.paintingRoom): true,
        SceneKey(SceneSet.defaultSet, SceneType.musicRoom): true,
      }, // Mở khóa cảnh mặc định
      currentPoints: 0,
      totalPoints: 0,
      lastPointsClaimDate: null,
    );
  }
  
  // Tạo bản sao với các thay đổi
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? mascotName,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
    Map<SceneKey, bool>? unlockedScenes,
    int? currentPoints,
    int? totalPoints,
    DateTime? lastPointsClaimDate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      mascotName: mascotName ?? this.mascotName,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      unlockedScenes: unlockedScenes ?? Map<SceneKey, bool>.from(this.unlockedScenes),
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      lastPointsClaimDate: lastPointsClaimDate ?? this.lastPointsClaimDate,
    );
  }
}