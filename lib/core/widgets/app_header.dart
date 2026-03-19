import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../l10n/app_localizations.dart';
import '../providers/score_provider.dart';
import '../utils/data_manager.dart';
import '../../screens/modals/settings_modal.dart';

/// Header cố định ở top màn hình
///
/// Layout: [Scene Shop] [Score] [Achievements] [Menu ☰]
/// - Menu ☰ chứa: Guide, Settings
/// - Background: transparent
/// - Items: primary bg, background text
class AppHeader extends StatefulWidget {
  final VoidCallback onSceneShopPressed;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onAchievementsPressed;

  const AppHeader({
    super.key,
    required this.onSceneShopPressed,
    this.onHelpPressed,
    this.onAchievementsPressed,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late int currentPoints;

  @override
  void initState() {
    super.initState();
    currentPoints = DataManager().userProfile.currentPoints;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Phương thức để cập nhật điểm số từ bên ngoài
  void updatePoints() {
    if (mounted) {
      setState(() {
        currentPoints = DataManager().userProfile.currentPoints;
      });
    }
  }

  Widget _buildMenuButton(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: 'Menu',
      button: true,
      enabled: true,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'guide') {
            widget.onHelpPressed!();
          } else if (value == 'settings') {
            SettingsModal.show(context);
          }
        },
        color: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 52),
        itemBuilder: (context) => [
          if (widget.onHelpPressed != null)
            PopupMenuItem<String>(
              value: 'guide',
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: theme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.tutorialTitle, style: AppTypography.bodyLarge(context, color: theme.text)),
                ],
              ),
            ),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, color: theme.primary, size: 20),
                const SizedBox(width: 12),
                Text(l10n.settings, style: AppTypography.bodyLarge(context, color: theme.text)),
              ],
            ),
          ),
        ],
        child: Material(
          color: theme.primary,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(Icons.menu, size: 24, color: theme.background),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currentPoints = context.watch<ScoreProvider>().currentPoints;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // [Shop]
          _buildHeaderButton(
            icon: Icons.landscape,
            onPressed: widget.onSceneShopPressed,
            theme: theme,
            label: 'Scene Shop',
          ),
          const Spacer(),
          // [Score]
          Semantics(
            label: 'Points: $currentPoints',
            readOnly: true,
            child: _buildCoinDisplay(currentPoints, theme),
          ),
          const Spacer(),
          // [Achievement]
          if (widget.onAchievementsPressed != null) ...[
            _buildHeaderButton(
              icon: Icons.emoji_events_outlined,
              onPressed: widget.onAchievementsPressed!,
              theme: theme,
              label: 'Achievements',
            ),
            const SizedBox(width: 8),
          ],
          // [Menu ☰]
          _buildMenuButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    required AppTheme theme,
    String? label,
  }) {
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      child: Material(
        color: theme.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: theme.background),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay(int points, AppTheme theme) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 160,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on, size: 20, color: theme.background),
          const SizedBox(width: 6),
          Flexible(
            child: Builder(
              builder: (context) => Text(
                points.toString(),
                style: AppTypography.labelLarge(context,
                  color: theme.background,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
