import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shapes.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/utils/achievement_service.dart';
import '../../core/widgets/app_modal.dart';

class AchievementsModal {
  AchievementsModal._();

  static Future<void> show(
    BuildContext context, {
    void Function(String featureId)? onNavigate,
  }) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.achievementsTitle,
      maxHeight: 680,
      content: _AchievementsContent(onNavigate: onNavigate),
    );
  }
}

class _AchievementsContent extends StatelessWidget {
  final void Function(String featureId)? onNavigate;

  const _AchievementsContent({this.onNavigate});

  static const _categoryOrder = [
    AchievementCategory.engagement,
    AchievementCategory.schedule,
    AchievementCategory.diary,
    AchievementCategory.breathing,
    AchievementCategory.sleep,
    AchievementCategory.garden,
    AchievementCategory.aquarium,
    AchievementCategory.painting,
    AchievementCategory.music,
    AchievementCategory.score,
  ];

  static const _categoryFeatureId = {
    AchievementCategory.schedule: 'schedule',
    AchievementCategory.diary: 'diary',
    AchievementCategory.breathing: 'breathing',
    AchievementCategory.sleep: 'sleep',
    AchievementCategory.garden: 'garden',
    AchievementCategory.aquarium: 'aquarium',
    AchievementCategory.painting: 'painting',
    AchievementCategory.music: 'music',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress =
        context.watch<AchievementProvider>().progress;

    final total = AchievementService.all.length;
    final unlocked = progress.unlockedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress summary
        _buildProgressHeader(context, l10n, unlocked, total),
        const SizedBox(height: 20),

        // Achievements grouped by category
        for (final cat in _categoryOrder) ...[
          _buildCategorySection(context, l10n, cat, progress),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildProgressHeader(
    BuildContext context,
    AppLocalizations l10n,
    int unlocked,
    int total,
  ) {
    final theme = context.theme;
    final fraction = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: context.shapes.medium.borderRadius as BorderRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: context.onPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / $total ${l10n.achievements}',
                  style: AppTypography.labelLarge(
                    context,
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor:
                        context.onSurfaceVariant.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(theme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    AppLocalizations l10n,
    AchievementCategory cat,
    dynamic progress,
  ) {
    final categoryAchievements = AchievementService.all
        .where((a) => a.category == cat)
        .toList();
    final featureId = _categoryFeatureId[cat];
    final totalPoints = context.watch<ScoreProvider>().profile.totalPoints;
    final progressText = _buildProgressText(l10n, cat, categoryAchievements, progress, totalPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                l10n.achievementCategoryName(cat.name),
                style: AppTypography.labelMedium(
                  context,
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (progressText != null) ...[
                Text(
                  progressText,
                  style: AppTypography.labelSmall(
                    context,
                    color: context.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onNavigate != null && featureId != null)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onNavigate!(featureId);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.goToFeature,
                        style: AppTypography.labelSmall(
                          context,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: context.primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Achievement cards
        ...categoryAchievements
            .map((ach) => _AchievementCard(
                  achievement: ach,
                  isUnlocked: progress.isUnlocked(ach.id),
                  unlockedAtMs: progress.unlockedAt[ach.id],
                )),
      ],
    );
  }

  /// Returns "x/y unit" for the next uncompleted achievement, or null if all done.
  String? _buildProgressText(
    AppLocalizations l10n,
    AchievementCategory cat,
    List<Achievement> achievements,
    dynamic progress,
    int totalPoints,
  ) {
    final Iterable<Achievement> locked = achievements.where((a) => !progress.isUnlocked(a.id));
    if (locked.isEmpty) return null;
    final info = _progressInfo(locked.first.id, progress, totalPoints);
    if (info == null) return null;
    return '${info.$1}/${info.$2} ${l10n.achievementUnit(info.$3)}';
  }

  static int _countBits(int n) {
    int c = 0;
    int v = n;
    while (v > 0) { c += v & 1; v >>= 1; }
    return c;
  }

  /// Returns (current, target, unitKey) for the given achievement ID, or null.
  static (int, int, String)? _progressInfo(String id, dynamic progress, int totalPoints) {
    int c(String key) => (progress.counters[key] as int?) ?? 0;
    return switch (id) {
      'days_7'              => (c(AchievementService.kDaysUsed), 7, 'days'),
      'days_30'             => (c(AchievementService.kDaysUsed), 30, 'days'),
      'app_explorer'        => (_countBits(c(AchievementService.kFeaturesUsed)), 3, 'features'),
      'schedule_task_10'    => (c(AchievementService.kScheduleTaskCount), 10, 'tasks'),
      'schedule_task_100'   => (c(AchievementService.kScheduleTaskCount), 100, 'tasks'),
      'schedule_task_300'   => (c(AchievementService.kScheduleTaskCount), 300, 'tasks'),
      'first_diary'         => (c(AchievementService.kDiaryCount), 1, 'entries'),
      'diary_20'            => (c(AchievementService.kDiaryCount), 20, 'entries'),
      'diary_50'            => (c(AchievementService.kDiaryCount), 50, 'entries'),
      'first_breath'        => (c(AchievementService.kBreathingTotal), 1, 'sessions'),
      'breathing_20'        => (c(AchievementService.kBreathingTotal), 20, 'sessions'),
      'breathing_100'       => (c(AchievementService.kBreathingTotal), 100, 'sessions'),
      'first_sleep_log'     => (c(AchievementService.kSleepLogCount), 1, 'logs'),
      'sleep_log_10'        => (c(AchievementService.kSleepLogCount), 10, 'logs'),
      'sleep_log_30'        => (c(AchievementService.kSleepLogCount), 30, 'logs'),
      'first_harvest'       => (c(AchievementService.kHarvestCount), 1, 'harvests'),
      'harvest_100'         => (c(AchievementService.kHarvestCount), 100, 'harvests'),
      'harvest_300'         => (c(AchievementService.kHarvestCount), 300, 'harvests'),
      'garden_points_1000'  => (c(AchievementService.kGardenPoints), 1000, 'points'),
      'garden_points_5000'  => (c(AchievementService.kGardenPoints), 5000, 'points'),
      'garden_points_10000' => (c(AchievementService.kGardenPoints), 10000, 'points'),
      'first_aquarium_claim'=> (c('aquarium_claim_count'), 1, 'claims'),
      'aquarium_points_1000'=> (c(AchievementService.kAquariumPoints), 1000, 'points'),
      'aquarium_points_5000'=> (c(AchievementService.kAquariumPoints), 5000, 'points'),
      'painting_pixels_512' => (c(AchievementService.kPixelsPainted), 512, 'pixels'),
      'painting_pixels_2560'=> (c(AchievementService.kPixelsPainted), 2560, 'pixels'),
      'painting_pixels_5120'=> (c(AchievementService.kPixelsPainted), 5120, 'pixels'),
      'music_notes_60'      => (c(AchievementService.kNotesChanged), 60, 'notes'),
      'music_notes_300'     => (c(AchievementService.kNotesChanged), 300, 'notes'),
      'music_notes_600'     => (c(AchievementService.kNotesChanged), 600, 'notes'),
      'score_1000'          => (totalPoints, 1000, 'points'),
      'score_5000'          => (totalPoints, 5000, 'points'),
      'score_20000'         => (totalPoints, 20000, 'points'),
      _                     => null,
    };
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final int? unlockedAtMs;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAtMs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

    final iconColor = isUnlocked ? theme.primary : context.onSurfaceVariant;
    final bgColor = isUnlocked
        ? theme.primary.withValues(alpha: 0.12)
        : context.onSurface.withValues(alpha: 0.06);
    final titleColor =
        isUnlocked ? theme.text : context.onSurfaceVariant;
    final descColor = isUnlocked
        ? context.onSurfaceVariant
        : context.onSurfaceVariant.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: context.shapes.medium.borderRadius as BorderRadius,
          border: Border.all(
            color: isUnlocked
                ? theme.primary.withValues(alpha: 0.25)
                : context.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(achievement.icon,
                      size: 22,
                      color: isUnlocked
                          ? iconColor
                          : iconColor.withValues(alpha: 0.45)),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: context.onSurfaceVariant.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 10,
                        color: context.surfaceColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.achievementTitle(achievement.id),
                    style: AppTypography.labelMedium(
                      context,
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.achievementDescription(achievement.id),
                    style: AppTypography.bodySmall(context, color: descColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: points or unlocked check
            if (isUnlocked)
              _buildUnlockedBadge(context, theme)
            else
              _buildPointsBadge(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedBadge(BuildContext context, dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_rounded,
          size: 16, color: theme.primary),
    );
  }

  Widget _buildPointsBadge(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    if (achievement.pointsReward <= 0) return const SizedBox(width: 28);
    return Column(
      children: [
        Icon(Icons.stars_rounded,
            size: 14, color: context.onSurfaceVariant.withValues(alpha: 0.45)),
        const SizedBox(height: 2),
        Text(
          '+${achievement.pointsReward}',
          style: AppTypography.bodySmall(
            context,
            color: context.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
