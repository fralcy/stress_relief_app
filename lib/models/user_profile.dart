import '../core/constants/app_assets.dart';
// Model cho thông tin cá nhân và cài đặt người dùng
class UserProfile {
  final String id;
  final String username;              // Username unique (để login)
  final String email;                 // Email (để login + recovery)
  final String name;                  // Tên người dùng
  final String mascotName;            // Tên linh vật
  final DateTime createdAt;
  final DateTime lastSyncedAt;        // Timestamp lần sync gần nhất
  
  // Progress
  final Map<SceneKey, bool> unlockedScenes;  // Các cảnh đã mở khóa
  
  // Points
  final int currentPoints;            // Điểm hiện có để tiêu
  final int totalPoints;              // Tổng điểm tích lũy (lifetime)
  
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
    );
  }
}