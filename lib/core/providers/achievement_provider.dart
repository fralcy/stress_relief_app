import 'package:flutter/material.dart';
import '../utils/achievement_service.dart';
import '../utils/data_manager.dart';
import '../../models/achievement_progress.dart';
import 'score_provider.dart';

/// Manages achievement state and provides trigger methods for UI layers.
///
/// Callers (modals / screens) invoke trigger methods, receive a list of
/// newly-unlocked [Achievement] objects, then show [AchievementPopup] for
/// each one. Points are awarded automatically via [ScoreProvider].
class AchievementProvider extends ChangeNotifier {
  AchievementProgress _progress = DataManager().achievementProgress;

  AchievementProgress get progress => _progress;

  /// Reload cached progress from DataManager.
  void refresh() {
    _progress = DataManager().achievementProgress;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // Trigger methods — call after the corresponding action
  // ----------------------------------------------------------

  Future<List<Achievement>> onAppOpened(ScoreProvider score) async {
    final ids = await AchievementService().onAppOpened();
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onFirstLaunch(ScoreProvider score) async {
    final ids = await AchievementService().onFirstLaunch();
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onScheduleClaimed(
    int count,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onScheduleClaimed(count);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onDiaryAdded(ScoreProvider score) async {
    final ids = await AchievementService().onDiaryAdded();
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onBreathingSessionCompleted(
    String exerciseKey,
    ScoreProvider score,
  ) async {
    final ids =
        await AchievementService().onBreathingSessionCompleted(exerciseKey);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onSleepLogAdded(
    int quality,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onSleepLogAdded(quality);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onHarvest(
    int pointsGained,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onHarvest(pointsGained: pointsGained);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onPlanted(ScoreProvider score) async {
    final ids = await AchievementService().onPlanted();
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onAquariumClaimed(
    int pointsClaimed,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onAquariumClaimed(pointsClaimed);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onFishFed(ScoreProvider score) async {
    final ids = await AchievementService().onFishFed();
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onFishCountChanged(
    int totalFishCount,
    ScoreProvider score,
  ) async {
    final ids =
        await AchievementService().onFishCountChanged(totalFishCount);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onPixelsPainted(
    int delta,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onPixelsPainted(delta: delta);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onNotesChanged(
    int delta,
    ScoreProvider score,
  ) async {
    final ids = await AchievementService().onNotesChanged(delta: delta);
    return _handleUnlocks(ids, score);
  }

  Future<List<Achievement>> onTotalPointsChanged(
    int totalPoints,
    ScoreProvider score,
  ) async {
    final ids =
        await AchievementService().onTotalPointsChanged(totalPoints);
    return _handleUnlocks(ids, score);
  }

  /// Run retroactive check for existing users.
  Future<void> retroactiveCheck(ScoreProvider score) async {
    final dm = DataManager();
    final diaryCount = dm.emotionDiaries.length;
    final breathingCount = dm.breathingSessions.length;
    final sleepLogCount = dm.sleepLogs.length;
    final scheduleTaskCount =
        dm.achievementProgress.counter(AchievementService.kScheduleTaskCount);
    final totalPoints = score.profile.totalPoints;

    final ids = await AchievementService().retroactiveCheck(
      diaryCount: diaryCount,
      breathingCount: breathingCount,
      sleepLogCount: sleepLogCount,
      scheduleTaskCount: scheduleTaskCount,
      totalPoints: totalPoints,
    );

    // Retroactive check does not show popups, but refresh cached state
    if (ids.isNotEmpty) refresh();
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  Future<List<Achievement>> _handleUnlocks(
    List<String> ids,
    ScoreProvider score,
  ) async {
    // Award points for each newly unlocked achievement
    for (final id in ids) {
      final ach = AchievementService.findById(id);
      if (ach != null && ach.pointsReward > 0) {
        await score.addPoints(ach.pointsReward);
      }
    }

    if (ids.isNotEmpty) {
      await AchievementService().clearNewlyUnlocked();
      refresh();
    }

    // Always check score-based achievements — score rewards are 0 so no recursion.
    // Must run even when ids is empty: feature actions (harvest, claim) add points
    // to ScoreProvider before this is called, so totalPoints may have crossed a
    // threshold without any tiered achievement unlocking in the same event.
    final newTotal = score.profile.totalPoints;
    final pointIds =
        await AchievementService().onTotalPointsChanged(newTotal);
    if (pointIds.isNotEmpty) {
      await AchievementService().clearNewlyUnlocked();
      refresh();
    }

    final newly = ids + pointIds;
    if (newly.isEmpty) return [];
    return newly
        .map(AchievementService.findById)
        .whereType<Achievement>()
        .toList();
  }
}
