import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_shapes.dart';
import '../constants/app_typography.dart';
import '../l10n/app_localizations.dart';
import '../utils/achievement_service.dart';

/// Displays a congratulatory popup for one or more newly-unlocked achievements.
///
/// Usage:
/// ```dart
/// final newly = await provider.onDiaryAdded(scoreProvider);
/// if (newly.isNotEmpty && mounted) {
///   AchievementPopup.show(context, newly);
/// }
/// ```
class AchievementPopup {
  AchievementPopup._();

  /// Shows each achievement in [achievements] as a brief dialog, one after another.
  static Future<void> show(
    BuildContext context,
    List<Achievement> achievements,
  ) async {
    for (final ach in achievements) {
      if (!context.mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Achievement',
        barrierColor: Colors.black.withValues(alpha: 0.35),
        transitionDuration: const Duration(milliseconds: 280),
        transitionBuilder: (ctx, animation, _, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
          return ScaleTransition(scale: curved, child: child);
        },
        pageBuilder: (ctx, _, _) => _AchievementDialog(achievement: ach),
      );
    }
  }
}

class _AchievementDialog extends StatefulWidget {
  final Achievement achievement;

  const _AchievementDialog({required this.achievement});

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3.5 seconds
    _autoCloseTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final ach = widget.achievement;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: context.shapes.extraLarge.borderRadius as BorderRadius,
            border: Border.all(color: context.outline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.vertical(
                    top: ((context.shapes.extraLarge.borderRadius
                            as BorderRadius)
                        .topLeft),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ach.icon,
                        color: context.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.achievementUnlocked,
                      style: AppTypography.labelLarge(
                        context,
                        color: theme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Achievement info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Text(
                      l10n.achievementTitle(ach.id),
                      style: AppTypography.h3(context, color: theme.text),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.achievementDescription(ach.id),
                      style: AppTypography.bodyMedium(
                        context,
                        color: context.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (ach.pointsReward > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.12),
                          borderRadius: context.shapes.small.borderRadius
                              as BorderRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 18, color: theme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '+${ach.pointsReward} ${l10n.points}',
                              style: AppTypography.labelLarge(
                                context,
                                color: theme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      l10n.tapToDismiss,
                      style: AppTypography.bodySmall(
                        context,
                        color: context.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
