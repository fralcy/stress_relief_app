import 'package:flutter/material.dart';
import 'data_manager.dart';
import '../../models/achievement_progress.dart';

// ============================================================
// Achievement definition (pure Dart config, no Hive)
// ============================================================

/// Categories for grouping achievements in the UI.
enum AchievementCategory {
  onboarding,
  diary,
  breathing,
  sleep,
  minigames,
  score,
}

/// Immutable config object for a single achievement.
class Achievement {
  final String id;
  final String Function() titleGetter;
  final String Function() descriptionGetter;
  final IconData icon;
  final int pointsReward;
  final AchievementCategory category;

  const Achievement({
    required this.id,
    required this.titleGetter,
    required this.descriptionGetter,
    required this.icon,
    required this.pointsReward,
    required this.category,
  });

  String get title => titleGetter();
  String get description => descriptionGetter();
}

// ============================================================
// AchievementService — singleton
// ============================================================

/// Manages achievement unlocking and progress tracking.
///
/// Callers invoke event methods (e.g. [onDiaryAdded]) after performing
/// actions. The service returns a list of newly-unlocked achievement IDs
/// so the caller can display a popup and award points.
///
/// Points are NOT awarded here — the caller should call
/// [ScoreProvider.addPoints] with [Achievement.pointsReward] for each ID.
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  // ----------------------------------------------------------
  // Counter keys (used in AchievementProgress.counters)
  // ----------------------------------------------------------
  static const String kDiaryCount = 'diary_count';
  static const String kDiaryStreak = 'diary_streak'; // consecutive days
  static const String kDiaryLastDate = 'diary_last_date'; // epoch day

  static const String kBreathingTotal = 'breathing_total'; // total sessions
  static const String kBreathing478 = 'breathing_478';     // 4-7-8 sessions
  static const String kBreathingBox = 'breathing_box';     // box breathing
  static const String kBreathingRelax = 'breathing_relax'; // 4-4-6-2 sessions

  static const String kSleepLogCount = 'sleep_log_count';
  static const String kSleepLogStreak = 'sleep_log_streak';
  static const String kSleepLogLastDate = 'sleep_log_last_date';
  static const String kSleepQualityHigh = 'sleep_quality_high'; // quality >= 4

  static const String kHarvestCount = 'harvest_count';
  static const String kFishCount = 'fish_count';
  static const String kPaintingCount = 'painting_count';
  static const String kMusicCount = 'music_count';

  // ----------------------------------------------------------
  // All 20 achievement definitions
  // ----------------------------------------------------------
  static final List<Achievement> all = [
    // === ONBOARDING (2) ===
    Achievement(
      id: 'first_steps',
      titleGetter: () => 'First Steps',
      descriptionGetter: () => 'Open the app for the first time',
      icon: Icons.star_outline,
      pointsReward: 10,
      category: AchievementCategory.onboarding,
    ),
    Achievement(
      id: 'app_explorer',
      titleGetter: () => 'App Explorer',
      descriptionGetter: () => 'Try 3 different features',
      icon: Icons.explore_outlined,
      pointsReward: 20,
      category: AchievementCategory.onboarding,
    ),

    // === DIARY (4) ===
    Achievement(
      id: 'first_diary',
      titleGetter: () => 'First Entry',
      descriptionGetter: () => 'Write your first emotion diary entry',
      icon: Icons.book_outlined,
      pointsReward: 15,
      category: AchievementCategory.diary,
    ),
    Achievement(
      id: 'diary_5',
      titleGetter: () => 'Getting Started',
      descriptionGetter: () => 'Write 5 diary entries',
      icon: Icons.edit_note,
      pointsReward: 25,
      category: AchievementCategory.diary,
    ),
    Achievement(
      id: 'diary_20',
      titleGetter: () => 'Consistent Writer',
      descriptionGetter: () => 'Write 20 diary entries',
      icon: Icons.history_edu,
      pointsReward: 50,
      category: AchievementCategory.diary,
    ),
    Achievement(
      id: 'diary_streak_7',
      titleGetter: () => 'Week of Reflection',
      descriptionGetter: () => 'Write diary entries 7 days in a row',
      icon: Icons.calendar_month,
      pointsReward: 75,
      category: AchievementCategory.diary,
    ),

    // === BREATHING (4) ===
    Achievement(
      id: 'first_breath',
      titleGetter: () => 'First Breath',
      descriptionGetter: () => 'Complete your first breathing session',
      icon: Icons.air,
      pointsReward: 15,
      category: AchievementCategory.breathing,
    ),
    Achievement(
      id: 'breathing_10',
      titleGetter: () => 'Mindful Breather',
      descriptionGetter: () => 'Complete 10 breathing sessions',
      icon: Icons.self_improvement,
      pointsReward: 40,
      category: AchievementCategory.breathing,
    ),
    Achievement(
      id: 'breathing_478_master',
      titleGetter: () => '4-7-8 Master',
      descriptionGetter: () => 'Complete 10 sessions of 4-7-8 breathing',
      icon: Icons.timer_outlined,
      pointsReward: 50,
      category: AchievementCategory.breathing,
    ),
    Achievement(
      id: 'breathing_box_master',
      titleGetter: () => 'Box Breathing Pro',
      descriptionGetter: () => 'Complete 10 sessions of box breathing',
      icon: Icons.check_box_outlined,
      pointsReward: 50,
      category: AchievementCategory.breathing,
    ),

    // === SLEEP (4) ===
    Achievement(
      id: 'first_sleep_log',
      titleGetter: () => 'Sleep Tracker',
      descriptionGetter: () => 'Log your sleep for the first time',
      icon: Icons.bedtime_outlined,
      pointsReward: 15,
      category: AchievementCategory.sleep,
    ),
    Achievement(
      id: 'sleep_log_7',
      titleGetter: () => 'Sleep Habit',
      descriptionGetter: () => 'Log your sleep 7 times',
      icon: Icons.nights_stay_outlined,
      pointsReward: 35,
      category: AchievementCategory.sleep,
    ),
    Achievement(
      id: 'sleep_streak_5',
      titleGetter: () => 'Sleep Streak',
      descriptionGetter: () => 'Log sleep 5 days in a row',
      icon: Icons.local_hotel_outlined,
      pointsReward: 60,
      category: AchievementCategory.sleep,
    ),
    Achievement(
      id: 'sleep_quality_high',
      titleGetter: () => 'Sweet Dreams',
      descriptionGetter: () => 'Log 5 nights with quality 4 or above',
      icon: Icons.star_half,
      pointsReward: 50,
      category: AchievementCategory.sleep,
    ),

    // === MINI-GAMES (4) ===
    Achievement(
      id: 'first_harvest',
      titleGetter: () => 'Green Thumb',
      descriptionGetter: () => 'Harvest a plant for the first time',
      icon: Icons.eco_outlined,
      pointsReward: 15,
      category: AchievementCategory.minigames,
    ),
    Achievement(
      id: 'harvest_10',
      titleGetter: () => 'Master Gardener',
      descriptionGetter: () => 'Harvest plants 10 times',
      icon: Icons.grass,
      pointsReward: 50,
      category: AchievementCategory.minigames,
    ),
    Achievement(
      id: 'aquarium_5_fish',
      titleGetter: () => 'Fish Collector',
      descriptionGetter: () => 'Own 5 fish in your aquarium',
      icon: Icons.phishing_outlined,
      pointsReward: 35,
      category: AchievementCategory.minigames,
    ),
    Achievement(
      id: 'first_painting',
      titleGetter: () => 'Artist',
      descriptionGetter: () => 'Save your first painting',
      icon: Icons.palette_outlined,
      pointsReward: 20,
      category: AchievementCategory.minigames,
    ),

    // === SCORE (2) ===
    Achievement(
      id: 'score_100',
      titleGetter: () => 'Century',
      descriptionGetter: () => 'Earn a total of 100 points',
      icon: Icons.looks_one_outlined,
      pointsReward: 0, // No reward to avoid infinite loop
      category: AchievementCategory.score,
    ),
    Achievement(
      id: 'score_500',
      titleGetter: () => 'High Achiever',
      descriptionGetter: () => 'Earn a total of 500 points',
      icon: Icons.emoji_events_outlined,
      pointsReward: 0,
      category: AchievementCategory.score,
    ),
  ];

  /// Quick lookup by ID.
  static final Map<String, Achievement> _byId = {
    for (final a in all) a.id: a,
  };

  static Achievement? findById(String id) => _byId[id];

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  AchievementProgress _load() => DataManager().achievementProgress;

  Future<void> _save(AchievementProgress p) =>
      DataManager().saveAchievementProgress(p);

  /// Try to unlock [ids]. Returns newly-unlocked IDs.
  List<String> _tryUnlock(AchievementProgress p, List<String> ids) {
    final newly = <String>[];
    for (final id in ids) {
      if (!p.unlockedIds.contains(id)) {
        p.unlockedIds.add(id);
        p.unlockedAt[id] =
            DateTime.now().millisecondsSinceEpoch;
        p.newlyUnlocked.add(id);
        newly.add(id);
      }
    }
    return newly;
  }

  /// Increment a counter and return the new value.
  int _increment(AchievementProgress p, String key, [int by = 1]) {
    final next = (p.counters[key] ?? 0) + by;
    p.counters[key] = next;
    return next;
  }

  /// Returns the current "epoch day" (days since epoch).
  int _epochDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day)
          .millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;

  /// Update a date-based streak counter. Returns the new streak value.
  int _updateStreak(
    AchievementProgress p,
    String streakKey,
    String lastDateKey,
  ) {
    final today = _epochDay(DateTime.now());
    final last = p.counters[lastDateKey] ?? -999;
    int streak;
    if (last == today) {
      streak = p.counters[streakKey] ?? 1; // already counted today
    } else if (last == today - 1) {
      streak = _increment(p, streakKey);
    } else {
      streak = 1;
      p.counters[streakKey] = 1;
    }
    p.counters[lastDateKey] = today;
    return streak;
  }

  // ----------------------------------------------------------
  // Feature-specific counter key for the "App Explorer" achievement
  // ----------------------------------------------------------
  static const String kFeaturesUsed = 'features_used';
  // Bit flags (use OR): diary=1, breathing=2, sleep=4, garden=8, aquarium=16, drawing=32, music=64
  static const int _kDiaryBit = 1;
  static const int _kBreathingBit = 2;
  static const int _kSleepBit = 4;
  static const int _kGardenBit = 8;
  static const int _kAquariumBit = 16;
  static const int _kDrawingBit = 32;
  static const int _kMusicBit = 64;

  int _countBits(int n) {
    int count = 0;
    while (n > 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
  }

  void _markFeatureUsed(AchievementProgress p, int bit) {
    p.counters[kFeaturesUsed] = (p.counters[kFeaturesUsed] ?? 0) | bit;
  }

  // ----------------------------------------------------------
  // Public trigger methods — call after the action succeeds
  // ----------------------------------------------------------

  /// Call when the user opens the app for the very first time.
  /// (Trigger from app initialization / onboarding screen.)
  Future<List<String>> onFirstLaunch() async {
    final p = _load();
    final ids = <String>['first_steps'];
    final newly = _tryUnlock(p, ids);
    if (newly.isNotEmpty) await _save(p);
    return newly;
  }

  /// Call after a diary entry is saved.
  Future<List<String>> onDiaryAdded() async {
    final p = _load();
    _markFeatureUsed(p, _kDiaryBit);

    final count = _increment(p, kDiaryCount);
    final streak = _updateStreak(p, kDiaryStreak, kDiaryLastDate);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      if (count >= 1) 'first_diary',
      if (count >= 5) 'diary_5',
      if (count >= 20) 'diary_20',
      if (streak >= 7) 'diary_streak_7',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a breathing session completes.
  /// [exerciseKey] matches the breathing exercise config key
  /// (e.g., '4-7-8', 'Box Breathing', '4-4-6-2').
  Future<List<String>> onBreathingSessionCompleted(String exerciseKey) async {
    final p = _load();
    _markFeatureUsed(p, _kBreathingBit);

    final total = _increment(p, kBreathingTotal);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    // Per-type counter
    final typeKey = _breathingCounterKey(exerciseKey);
    final typeCount = _increment(p, typeKey);

    final candidates = <String>[
      if (total >= 1) 'first_breath',
      if (total >= 10) 'breathing_10',
      if (typeKey == kBreathing478 && typeCount >= 10) 'breathing_478_master',
      if (typeKey == kBreathingBox && typeCount >= 10) 'breathing_box_master',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  String _breathingCounterKey(String exerciseKey) {
    final lower = exerciseKey.toLowerCase();
    if (lower.contains('4-7-8') || lower.contains('478')) return kBreathing478;
    if (lower.contains('box')) return kBreathingBox;
    if (lower.contains('4-4-6') || lower.contains('relax')) return kBreathingRelax;
    return 'breathing_other';
  }

  /// Call after a sleep log entry is saved.
  /// [quality] is 1-5 (the star rating from SleepLog).
  Future<List<String>> onSleepLogAdded(int quality) async {
    final p = _load();
    _markFeatureUsed(p, _kSleepBit);

    final count = _increment(p, kSleepLogCount);
    final streak = _updateStreak(p, kSleepLogStreak, kSleepLogLastDate);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    if (quality >= 4) {
      _increment(p, kSleepQualityHigh);
    }
    final highQuality = p.counters[kSleepQualityHigh] ?? 0;

    final candidates = <String>[
      if (count >= 1) 'first_sleep_log',
      if (count >= 7) 'sleep_log_7',
      if (streak >= 5) 'sleep_streak_5',
      if (highQuality >= 5) 'sleep_quality_high',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a plant is harvested in the garden.
  Future<List<String>> onHarvest() async {
    final p = _load();
    _markFeatureUsed(p, _kGardenBit);

    final count = _increment(p, kHarvestCount);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      if (count >= 1) 'first_harvest',
      if (count >= 10) 'harvest_10',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a fish is bought. [totalFishCount] is the current total.
  Future<List<String>> onFishCountChanged(int totalFishCount) async {
    final p = _load();
    _markFeatureUsed(p, _kAquariumBit);
    p.counters[kFishCount] = totalFishCount;

    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      if (totalFishCount >= 5) 'aquarium_5_fish',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a painting is saved.
  Future<List<String>> onPaintingSaved() async {
    final p = _load();
    _markFeatureUsed(p, _kDrawingBit);

    _increment(p, kPaintingCount);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      'first_painting',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a music track is saved.
  Future<List<String>> onMusicTrackSaved() async {
    final p = _load();
    _markFeatureUsed(p, _kMusicBit);

    _increment(p, kMusicCount);
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      if (featuresUsed >= 3) 'app_explorer',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call whenever the user's total points change (e.g. after [ScoreProvider.addPoints]).
  /// [totalPoints] is [UserProfile.totalPoints].
  Future<List<String>> onTotalPointsChanged(int totalPoints) async {
    final p = _load();

    final candidates = <String>[
      if (totalPoints >= 100) 'score_100',
      if (totalPoints >= 500) 'score_500',
    ];

    final newly = _tryUnlock(p, candidates);
    if (newly.isNotEmpty) await _save(p);
    return newly;
  }

  /// Mark the newly-unlocked queue as displayed (call after showing popups).
  Future<void> clearNewlyUnlocked() async {
    final p = _load();
    if (p.newlyUnlocked.isNotEmpty) {
      p.newlyUnlocked.clear();
      await _save(p);
    }
  }

  /// Retroactive unlock check — run once after login/app update.
  /// Checks existing data counts and unlocks any missed achievements.
  Future<List<String>> retroactiveCheck({
    required int diaryCount,
    required int breathingCount,
    required int sleepLogCount,
    required int harvestCount,
    required int fishCount,
    required int paintingCount,
    required int totalPoints,
  }) async {
    final p = _load();

    // Ensure counters reflect reality (only increase, never decrease)
    if ((p.counters[kDiaryCount] ?? 0) < diaryCount) {
      p.counters[kDiaryCount] = diaryCount;
    }
    if ((p.counters[kBreathingTotal] ?? 0) < breathingCount) {
      p.counters[kBreathingTotal] = breathingCount;
    }
    if ((p.counters[kSleepLogCount] ?? 0) < sleepLogCount) {
      p.counters[kSleepLogCount] = sleepLogCount;
    }
    if ((p.counters[kHarvestCount] ?? 0) < harvestCount) {
      p.counters[kHarvestCount] = harvestCount;
    }
    if ((p.counters[kFishCount] ?? 0) < fishCount) {
      p.counters[kFishCount] = fishCount;
    }
    if ((p.counters[kPaintingCount] ?? 0) < paintingCount) {
      p.counters[kPaintingCount] = paintingCount;
    }

    // Mark features used based on counts
    if (diaryCount > 0) _markFeatureUsed(p, _kDiaryBit);
    if (breathingCount > 0) _markFeatureUsed(p, _kBreathingBit);
    if (sleepLogCount > 0) _markFeatureUsed(p, _kSleepBit);
    if (harvestCount > 0) _markFeatureUsed(p, _kGardenBit);
    if (fishCount > 0) _markFeatureUsed(p, _kAquariumBit);
    if (paintingCount > 0) _markFeatureUsed(p, _kDrawingBit);

    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    final candidates = <String>[
      'first_steps', // always unlock retroactively
      if (diaryCount >= 1) 'first_diary',
      if (diaryCount >= 5) 'diary_5',
      if (diaryCount >= 20) 'diary_20',
      if (breathingCount >= 1) 'first_breath',
      if (breathingCount >= 10) 'breathing_10',
      if (sleepLogCount >= 1) 'first_sleep_log',
      if (sleepLogCount >= 7) 'sleep_log_7',
      if (harvestCount >= 1) 'first_harvest',
      if (harvestCount >= 10) 'harvest_10',
      if (fishCount >= 5) 'aquarium_5_fish',
      if (paintingCount >= 1) 'first_painting',
      if (totalPoints >= 100) 'score_100',
      if (totalPoints >= 500) 'score_500',
      if (featuresUsed >= 3) 'app_explorer',
    ];

    // Retroactive unlocks do NOT add to newlyUnlocked (no popup spam)
    final newly = <String>[];
    for (final id in candidates) {
      if (!p.unlockedIds.contains(id)) {
        p.unlockedIds.add(id);
        p.unlockedAt[id] = DateTime.now().millisecondsSinceEpoch;
        newly.add(id);
      }
    }

    await _save(p);
    return newly;
  }
}
