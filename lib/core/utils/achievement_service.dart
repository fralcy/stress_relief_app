import 'package:flutter/material.dart';
import 'data_manager.dart';
import '../../models/achievement_progress.dart';

// ============================================================
// Achievement definition (pure Dart config, no Hive)
// ============================================================

/// Categories for grouping achievements in the UI.
enum AchievementCategory {
  engagement, // general app engagement — shown first
  schedule,
  diary,
  breathing,
  sleep,
  garden,
  aquarium,
  painting,
  music,
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
  static const String kDaysUsed = 'days_used';

  static const String kDiaryCount = 'diary_count';

  static const String kBreathingTotal = 'breathing_total';

  static const String kSleepLogCount = 'sleep_log_count';

  static const String kPlantCount = 'plant_count';
  static const String kGardenPoints = 'garden_points';   // stat only (profile display)

  static const String kFishFedCount = 'fish_fed_count';
  static const String kAquariumPoints = 'aquarium_points'; // stat only (profile display)

  static const String kPixelsPainted = 'pixels_painted';

  static const String kNotesChanged = 'notes_changed';

  static const String kScheduleTaskCount = 'schedule_task_count';

  /// Internal flag — set to 1 after retroactiveCheck runs, so it only runs once.
  static const String _kRetroactiveDone = 'retroactive_done';

  // ----------------------------------------------------------
  // All 33 achievement definitions
  // ----------------------------------------------------------
  static final List<Achievement> all = [
    // === ENGAGEMENT (4) ===
    Achievement(
      id: 'first_steps',
      titleGetter: () => 'First Steps',
      descriptionGetter: () => 'Open the app for the first time',
      icon: Icons.star_outline,
      pointsReward: 10,
      category: AchievementCategory.engagement,
    ),
    Achievement(
      id: 'app_explorer',
      titleGetter: () => 'App Explorer',
      descriptionGetter: () => 'Try 3 different features',
      icon: Icons.explore_outlined,
      pointsReward: 20,
      category: AchievementCategory.engagement,
    ),
    Achievement(
      id: 'days_7',
      titleGetter: () => 'Regular User',
      descriptionGetter: () => 'Use the app on 7 different days',
      icon: Icons.calendar_today_outlined,
      pointsReward: 30,
      category: AchievementCategory.engagement,
    ),
    Achievement(
      id: 'days_30',
      titleGetter: () => 'Devoted User',
      descriptionGetter: () => 'Use the app on 30 different days',
      icon: Icons.calendar_month_outlined,
      pointsReward: 100,
      category: AchievementCategory.engagement,
    ),

    // === SCHEDULE (4) ===
    Achievement(
      id: 'first_schedule_task',
      titleGetter: () => 'First Task',
      descriptionGetter: () => 'Complete your first scheduled task',
      icon: Icons.add_task,
      pointsReward: 15,
      category: AchievementCategory.schedule,
    ),
    Achievement(
      id: 'schedule_task_15',
      titleGetter: () => 'Planner',
      descriptionGetter: () => 'Complete 15 scheduled tasks',
      icon: Icons.check_circle_outline,
      pointsReward: 15,
      category: AchievementCategory.schedule,
    ),
    Achievement(
      id: 'schedule_task_75',
      titleGetter: () => 'Disciplined',
      descriptionGetter: () => 'Complete 75 scheduled tasks',
      icon: Icons.task_alt,
      pointsReward: 40,
      category: AchievementCategory.schedule,
    ),
    Achievement(
      id: 'schedule_task_150',
      titleGetter: () => 'Schedule Master',
      descriptionGetter: () => 'Complete 150 scheduled tasks',
      icon: Icons.event_available,
      pointsReward: 100,
      category: AchievementCategory.schedule,
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
      titleGetter: () => 'Budding Diarist',
      descriptionGetter: () => 'Write 5 diary entries',
      icon: Icons.edit_note,
      pointsReward: 25,
      category: AchievementCategory.diary,
    ),
    Achievement(
      id: 'diary_15',
      titleGetter: () => 'Consistent Writer',
      descriptionGetter: () => 'Write 15 diary entries',
      icon: Icons.auto_stories,
      pointsReward: 50,
      category: AchievementCategory.diary,
    ),
    Achievement(
      id: 'diary_30',
      titleGetter: () => 'Inner Writer',
      descriptionGetter: () => 'Write 30 diary entries',
      icon: Icons.history_edu,
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
      id: 'breathing_5',
      titleGetter: () => 'Calm Seeker',
      descriptionGetter: () => 'Complete 5 breathing sessions',
      icon: Icons.self_improvement,
      pointsReward: 25,
      category: AchievementCategory.breathing,
    ),
    Achievement(
      id: 'breathing_15',
      titleGetter: () => 'Mindful Breather',
      descriptionGetter: () => 'Complete 15 breathing sessions',
      icon: Icons.air_outlined,
      pointsReward: 50,
      category: AchievementCategory.breathing,
    ),
    Achievement(
      id: 'breathing_30',
      titleGetter: () => 'Breathing Master',
      descriptionGetter: () => 'Complete 30 breathing sessions',
      icon: Icons.spa_outlined,
      pointsReward: 75,
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
      id: 'sleep_log_5',
      titleGetter: () => 'Rest Starter',
      descriptionGetter: () => 'Log your sleep 5 times',
      icon: Icons.nights_stay_outlined,
      pointsReward: 25,
      category: AchievementCategory.sleep,
    ),
    Achievement(
      id: 'sleep_log_15',
      titleGetter: () => 'Sleep Habit',
      descriptionGetter: () => 'Log your sleep 15 times',
      icon: Icons.dark_mode_outlined,
      pointsReward: 50,
      category: AchievementCategory.sleep,
    ),
    Achievement(
      id: 'sleep_log_30',
      titleGetter: () => 'Sleep Expert',
      descriptionGetter: () => 'Log your sleep 30 times',
      icon: Icons.local_hotel_outlined,
      pointsReward: 75,
      category: AchievementCategory.sleep,
    ),

    // === GARDEN (4) ===
    Achievement(
      id: 'first_plant',
      titleGetter: () => 'Green Thumb',
      descriptionGetter: () => 'Plant your first seed',
      icon: Icons.eco_outlined,
      pointsReward: 15,
      category: AchievementCategory.garden,
    ),
    Achievement(
      id: 'plant_30',
      titleGetter: () => 'Seedling Keeper',
      descriptionGetter: () => 'Plant seeds 30 times',
      icon: Icons.local_florist_outlined,
      pointsReward: 25,
      category: AchievementCategory.garden,
    ),
    Achievement(
      id: 'plant_80',
      titleGetter: () => 'Patient Gardener',
      descriptionGetter: () => 'Plant seeds 80 times',
      icon: Icons.grass,
      pointsReward: 50,
      category: AchievementCategory.garden,
    ),
    Achievement(
      id: 'plant_160',
      titleGetter: () => 'Master Gardener',
      descriptionGetter: () => 'Plant seeds 160 times',
      icon: Icons.agriculture,
      pointsReward: 100,
      category: AchievementCategory.garden,
    ),

    // === AQUARIUM (4) ===
    Achievement(
      id: 'first_fish_fed',
      titleGetter: () => 'First Feeding',
      descriptionGetter: () => 'Feed your fish for the first time',
      icon: Icons.water_drop_outlined,
      pointsReward: 15,
      category: AchievementCategory.aquarium,
    ),
    Achievement(
      id: 'fish_fed_15',
      titleGetter: () => 'Fish Friend',
      descriptionGetter: () => 'Feed your fish 15 times',
      icon: Icons.water_outlined,
      pointsReward: 25,
      category: AchievementCategory.aquarium,
    ),
    Achievement(
      id: 'fish_fed_150',
      titleGetter: () => 'Fish Keeper',
      descriptionGetter: () => 'Feed your fish 150 times',
      icon: Icons.waves_outlined,
      pointsReward: 40,
      category: AchievementCategory.aquarium,
    ),
    Achievement(
      id: 'fish_fed_300',
      titleGetter: () => 'Fish Master',
      descriptionGetter: () => 'Feed your fish 300 times',
      icon: Icons.water,
      pointsReward: 100,
      category: AchievementCategory.aquarium,
    ),

    // === PAINTING (4) ===
    Achievement(
      id: 'first_painting',
      titleGetter: () => 'First Stroke',
      descriptionGetter: () => 'Paint your first pixel',
      icon: Icons.color_lens_outlined,
      pointsReward: 15,
      category: AchievementCategory.painting,
    ),
    Achievement(
      id: 'painting_pixels_512',
      titleGetter: () => 'Budding Artist',
      descriptionGetter: () => 'Paint 512 pixels',
      icon: Icons.palette_outlined,
      pointsReward: 15,
      category: AchievementCategory.painting,
    ),
    Achievement(
      id: 'painting_pixels_2560',
      titleGetter: () => 'Art Gallery',
      descriptionGetter: () => 'Paint 2,560 pixels',
      icon: Icons.brush_outlined,
      pointsReward: 35,
      category: AchievementCategory.painting,
    ),
    Achievement(
      id: 'painting_pixels_5120',
      titleGetter: () => 'Master Artist',
      descriptionGetter: () => 'Paint 5,120 pixels',
      icon: Icons.draw_outlined,
      pointsReward: 75,
      category: AchievementCategory.painting,
    ),

    // === MUSIC (4) ===
    Achievement(
      id: 'first_music',
      titleGetter: () => 'First Note',
      descriptionGetter: () => 'Place your first note in a composition',
      icon: Icons.piano,
      pointsReward: 15,
      category: AchievementCategory.music,
    ),
    Achievement(
      id: 'music_notes_60',
      titleGetter: () => 'First Melody',
      descriptionGetter: () => 'Place 60 notes in your compositions',
      icon: Icons.music_note_outlined,
      pointsReward: 15,
      category: AchievementCategory.music,
    ),
    Achievement(
      id: 'music_notes_300',
      titleGetter: () => 'Music Maker',
      descriptionGetter: () => 'Place 300 notes in your compositions',
      icon: Icons.queue_music_outlined,
      pointsReward: 35,
      category: AchievementCategory.music,
    ),
    Achievement(
      id: 'music_notes_600',
      titleGetter: () => 'Music Master',
      descriptionGetter: () => 'Place 600 notes in your compositions',
      icon: Icons.library_music_outlined,
      pointsReward: 75,
      category: AchievementCategory.music,
    ),

    // === SCORE (3) ===
    Achievement(
      id: 'score_1000',
      titleGetter: () => 'Score: 1K',
      descriptionGetter: () => 'Earn a total of 1,000 points',
      icon: Icons.looks_one_outlined,
      pointsReward: 0, // No reward to avoid infinite loop
      category: AchievementCategory.score,
    ),
    Achievement(
      id: 'score_5000',
      titleGetter: () => 'Score: 5K',
      descriptionGetter: () => 'Earn a total of 5,000 points',
      icon: Icons.military_tech_outlined,
      pointsReward: 0,
      category: AchievementCategory.score,
    ),
    Achievement(
      id: 'score_20000',
      titleGetter: () => 'Score: 20K',
      descriptionGetter: () => 'Earn a total of 20,000 points',
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

  // ----------------------------------------------------------
  // Feature-specific counter key for the "App Explorer" achievement
  // ----------------------------------------------------------
  static const String kFeaturesUsed = 'features_used';
  // Bit flags (use OR): schedule=1, diary=2, breathing=4, sleep=8, garden=16, aquarium=32, drawing=64, music=128
  static const int _kScheduleBit = 1;
  static const int _kDiaryBit = 2;
  static const int _kBreathingBit = 4;
  static const int _kSleepBit = 8;
  static const int _kGardenBit = 16;
  static const int _kAquariumBit = 32;
  static const int _kDrawingBit = 64;
  static const int _kMusicBit = 128;

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

  List<String> _appExplorerCandidates(AchievementProgress p) {
    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);
    return [if (featuresUsed >= 3) 'app_explorer'];
  }

  // ----------------------------------------------------------
  // Public trigger methods — call after the action succeeds
  // ----------------------------------------------------------

  /// Call when the user opens the app (once per day — idempotent).
  Future<List<String>> onAppOpened() async {
    final p = _load();
    final today = _epochDay(DateTime.now());
    final last = p.counters['days_last'] ?? -999;
    if (last == today) return []; // already counted today
    p.counters['days_last'] = today;
    final total = _increment(p, kDaysUsed);

    final candidates = <String>[
      if (total >= 7) 'days_7',
      if (total >= 30) 'days_30',
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call when the user opens the app for the very first time.
  Future<List<String>> onFirstLaunch() async {
    final p = _load();
    final today = _epochDay(DateTime.now());
    p.counters['days_last'] = today;
    _increment(p, kDaysUsed); // counts as day 1
    final newly = _tryUnlock(p, ['first_steps']);
    if (newly.isNotEmpty) await _save(p);
    return newly;
  }

  /// Call when the user claims daily schedule points. [count] is the number
  /// of completed tasks at the time of claiming.
  Future<List<String>> onScheduleClaimed(int count) async {
    if (count <= 0) return [];
    final p = _load();
    _markFeatureUsed(p, _kScheduleBit);
    final total = _increment(p, kScheduleTaskCount, count);

    final candidates = <String>[
      if (total >= 1) 'first_schedule_task',
      if (total >= 15) 'schedule_task_15',
      if (total >= 75) 'schedule_task_75',
      if (total >= 150) 'schedule_task_150',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a diary entry is saved.
  Future<List<String>> onDiaryAdded() async {
    final p = _load();
    _markFeatureUsed(p, _kDiaryBit);
    final count = _increment(p, kDiaryCount);

    final candidates = <String>[
      if (count >= 1) 'first_diary',
      if (count >= 5) 'diary_5',
      if (count >= 15) 'diary_15',
      if (count >= 30) 'diary_30',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a breathing session completes.
  Future<List<String>> onBreathingSessionCompleted(String exerciseKey) async {
    final p = _load();
    _markFeatureUsed(p, _kBreathingBit);
    final total = _increment(p, kBreathingTotal);

    final candidates = <String>[
      if (total >= 1) 'first_breath',
      if (total >= 5) 'breathing_5',
      if (total >= 15) 'breathing_15',
      if (total >= 30) 'breathing_30',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a sleep log entry is saved.
  Future<List<String>> onSleepLogAdded(int quality) async {
    final p = _load();
    _markFeatureUsed(p, _kSleepBit);
    final count = _increment(p, kSleepLogCount);

    final candidates = <String>[
      if (count >= 1) 'first_sleep_log',
      if (count >= 5) 'sleep_log_5',
      if (count >= 15) 'sleep_log_15',
      if (count >= 30) 'sleep_log_30',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a plant is harvested. Tracks garden_points stat only — no achievement candidates.
  Future<List<String>> onHarvest({required int pointsGained}) async {
    final p = _load();
    _markFeatureUsed(p, _kGardenBit);
    _increment(p, kGardenPoints, pointsGained);
    final candidates = _appExplorerCandidates(p);
    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a seed is planted.
  Future<List<String>> onPlanted() async {
    final p = _load();
    _markFeatureUsed(p, _kGardenBit);
    final count = _increment(p, kPlantCount);

    final candidates = <String>[
      if (count >= 1) 'first_plant',
      if (count >= 30) 'plant_30',
      if (count >= 80) 'plant_80',
      if (count >= 160) 'plant_160',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after coins are claimed from the aquarium. Tracks aquarium_points stat only — no achievement candidates.
  Future<List<String>> onAquariumClaimed(int pointsClaimed) async {
    final p = _load();
    _markFeatureUsed(p, _kAquariumBit);
    _increment(p, kAquariumPoints, pointsClaimed);
    final candidates = _appExplorerCandidates(p);
    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call after a fish is fed.
  Future<List<String>> onFishFed() async {
    final p = _load();
    _markFeatureUsed(p, _kAquariumBit);
    final count = _increment(p, kFishFedCount);

    final candidates = <String>[
      if (count >= 1) 'first_fish_fed',
      if (count >= 15) 'fish_fed_15',
      if (count >= 150) 'fish_fed_150',
      if (count >= 300) 'fish_fed_300',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call when fish count changes (buy/sell) — marks feature used only.
  Future<List<String>> onFishCountChanged(int totalFishCount) async {
    final p = _load();
    _markFeatureUsed(p, _kAquariumBit);
    final candidates = _appExplorerCandidates(p);
    final newly = _tryUnlock(p, candidates);
    if (newly.isNotEmpty) await _save(p);
    return newly;
  }

  /// Call after pixels are painted. [delta] is the number of pixel changes this session.
  Future<List<String>> onPixelsPainted({required int delta}) async {
    final p = _load();
    _markFeatureUsed(p, _kDrawingBit);
    final total = _increment(p, kPixelsPainted, delta);

    final candidates = <String>[
      if (total >= 1) 'first_painting',
      if (total >= 512) 'painting_pixels_512',
      if (total >= 2560) 'painting_pixels_2560',
      if (total >= 5120) 'painting_pixels_5120',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Persist [delta] note changes without checking thresholds.
  /// Used for fire-and-forget flush on modal dispose.
  Future<void> addNotesOnly(int delta) async {
    if (delta <= 0) return;
    final p = _load();
    _increment(p, kNotesChanged, delta);
    await _save(p);
  }

  /// Persist [delta] pixel paints without checking thresholds.
  /// Used for fire-and-forget flush on modal dispose.
  Future<void> addPixelsOnly(int delta) async {
    if (delta <= 0) return;
    final p = _load();
    _increment(p, kPixelsPainted, delta);
    await _save(p);
  }

  /// Call after notes are changed. [delta] is the number of note toggles this session.
  Future<List<String>> onNotesChanged({required int delta}) async {
    final p = _load();
    _markFeatureUsed(p, _kMusicBit);
    final total = _increment(p, kNotesChanged, delta);

    final candidates = <String>[
      if (total >= 1) 'first_music',
      if (total >= 60) 'music_notes_60',
      if (total >= 300) 'music_notes_300',
      if (total >= 600) 'music_notes_600',
      ..._appExplorerCandidates(p),
    ];

    final newly = _tryUnlock(p, candidates);
    await _save(p);
    return newly;
  }

  /// Call whenever the user's total points change.
  Future<List<String>> onTotalPointsChanged(int totalPoints) async {
    final p = _load();

    final candidates = <String>[
      if (totalPoints >= 1000) 'score_1000',
      if (totalPoints >= 5000) 'score_5000',
      if (totalPoints >= 20000) 'score_20000',
    ];

    final newly = _tryUnlock(p, candidates);
    if (newly.isNotEmpty) await _save(p);
    return newly;
  }

  /// Mark the newly-unlocked queue as displayed.
  Future<void> clearNewlyUnlocked() async {
    final p = _load();
    if (p.newlyUnlocked.isNotEmpty) {
      p.newlyUnlocked.clear();
      await _save(p);
    }
  }

  /// Retroactive unlock check — run once after login/app update.
  Future<List<String>> retroactiveCheck({
    required int diaryCount,
    required int breathingCount,
    required int sleepLogCount,
    required int scheduleTaskCount,
    required int totalPoints,
  }) async {
    final p = _load();

    // Only run once per install — prevents silently re-locking achievements
    // that users should earn via normal play with a popup.
    if ((p.counters[_kRetroactiveDone] ?? 0) == 1) return [];
    p.counters[_kRetroactiveDone] = 1;

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
    if ((p.counters[kScheduleTaskCount] ?? 0) < scheduleTaskCount) {
      p.counters[kScheduleTaskCount] = scheduleTaskCount;
    }

    // Mark features used based on counts
    if (scheduleTaskCount > 0) _markFeatureUsed(p, _kScheduleBit);
    if (diaryCount > 0) _markFeatureUsed(p, _kDiaryBit);
    if (breathingCount > 0) _markFeatureUsed(p, _kBreathingBit);
    if (sleepLogCount > 0) _markFeatureUsed(p, _kSleepBit);

    final featuresUsed = _countBits(p.counters[kFeaturesUsed] ?? 0);

    // Garden and aquarium achievements are based on in-session counters (plant_count, fish_fed_count)
    final plantCount = p.counters[kPlantCount] ?? 0;
    final fishFedCount = p.counters[kFishFedCount] ?? 0;
    if (plantCount > 0) _markFeatureUsed(p, _kGardenBit);
    if (fishFedCount > 0) _markFeatureUsed(p, _kAquariumBit);

    final candidates = <String>[
      if (diaryCount >= 1) 'first_diary',
      if (diaryCount >= 5) 'diary_5',
      if (diaryCount >= 15) 'diary_15',
      if (diaryCount >= 30) 'diary_30',
      if (breathingCount >= 1) 'first_breath',
      if (breathingCount >= 5) 'breathing_5',
      if (breathingCount >= 15) 'breathing_15',
      if (breathingCount >= 30) 'breathing_30',
      if (sleepLogCount >= 1) 'first_sleep_log',
      if (sleepLogCount >= 5) 'sleep_log_5',
      if (sleepLogCount >= 15) 'sleep_log_15',
      if (sleepLogCount >= 30) 'sleep_log_30',
      if (plantCount >= 1) 'first_plant',
      if (plantCount >= 30) 'plant_30',
      if (plantCount >= 80) 'plant_80',
      if (plantCount >= 160) 'plant_160',
      if (fishFedCount >= 1) 'first_fish_fed',
      if (fishFedCount >= 15) 'fish_fed_15',
      if (fishFedCount >= 150) 'fish_fed_150',
      if (fishFedCount >= 300) 'fish_fed_300',
      if (scheduleTaskCount >= 1) 'first_schedule_task',
      if (scheduleTaskCount >= 15) 'schedule_task_15',
      if (scheduleTaskCount >= 75) 'schedule_task_75',
      if (scheduleTaskCount >= 150) 'schedule_task_150',
      if ((p.counters[kPixelsPainted] ?? 0) >= 1) 'first_painting',
      if ((p.counters[kNotesChanged] ?? 0) >= 1) 'first_music',
      if (totalPoints >= 1000) 'score_1000',
      if (totalPoints >= 5000) 'score_5000',
      if (totalPoints >= 20000) 'score_20000',
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
