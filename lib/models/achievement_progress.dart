import 'package:hive/hive.dart';

part 'achievement_progress.g.dart';

@HiveType(typeId: 22)
class AchievementProgress extends HiveObject {
  /// IDs of all unlocked achievements
  @HiveField(0)
  List<String> unlockedIds;

  /// Generic counters used to track progress toward achievements.
  /// Keys are counter names (e.g., 'diary_count', 'breathing_4_7_8').
  @HiveField(1)
  Map<String, int> counters;

  /// Unix timestamp (millisecondsSinceEpoch) when each achievement was unlocked.
  /// Keyed by achievement ID.
  @HiveField(2)
  Map<String, int> unlockedAt;

  /// IDs that have been unlocked but not yet shown as a popup.
  /// Cleared after the popup is displayed.
  @HiveField(3)
  List<String> newlyUnlocked;

  AchievementProgress({
    required this.unlockedIds,
    required this.counters,
    required this.unlockedAt,
    required this.newlyUnlocked,
  });

  factory AchievementProgress.initial() => AchievementProgress(
        unlockedIds: [],
        counters: {},
        unlockedAt: {},
        newlyUnlocked: [],
      );

  bool isUnlocked(String id) => unlockedIds.contains(id);

  int counter(String key) => counters[key] ?? 0;
}
