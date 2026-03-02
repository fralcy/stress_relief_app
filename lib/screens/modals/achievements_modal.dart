import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shapes.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/utils/achievement_service.dart';
import '../../core/widgets/app_modal.dart';

class AchievementsModal {
  AchievementsModal._();

  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.achievementsTitle,
      maxHeight: 680,
      content: const _AchievementsContent(),
    );
  }
}

class _AchievementsContent extends StatelessWidget {
  const _AchievementsContent();

  static const _categoryOrder = [
    AchievementCategory.onboarding,
    AchievementCategory.diary,
    AchievementCategory.breathing,
    AchievementCategory.sleep,
    AchievementCategory.minigames,
    AchievementCategory.score,
  ];

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.achievementCategoryName(cat.name),
            style: AppTypography.labelMedium(
              context,
              color: context.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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
