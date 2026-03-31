import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/avatar_presets.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';

class ProfileModal {
  ProfileModal._();

  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    return AppModal.show(
      context: context,
      title: l10n.menuProfile,
      maxHeight: screenHeight * 0.92,
      content: const _ProfileContent(),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent();

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  late final TextEditingController _nameCtrl;
  late int _selectedIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = DataManager().userProfile;
    _nameCtrl = TextEditingController(text: profile.name);
    _selectedIndex = profile.resolvedAvatarIndex;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final profile = DataManager().userProfile;
    await DataManager().saveUserProfile(
      profile.copyWith(name: name, avatarIndex: _selectedIndex),
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final profile = DataManager().userProfile;
    final counters = DataManager().achievementProgress.counters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section A: Identity ──────────────────────────────
        _sectionHeader(context, theme, l10n.editProfile),
        const SizedBox(height: 12),

        // Current avatar display
        Center(
          child: Text(
            kAvatarPresets[_selectedIndex],
            style: const TextStyle(fontSize: 56),
          ),
        ),
        const SizedBox(height: 12),

        // Avatar grid picker
        Text(
          l10n.chooseAvatar,
          style: AppTypography.bodySmall(context,
              color: theme.text.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 8),
        _buildAvatarGrid(theme),
        const SizedBox(height: 20),

        // Name field
        TextField(
          controller: _nameCtrl,
          style: AppTypography.bodyMedium(context, color: theme.text),
          decoration: InputDecoration(
            labelText: l10n.name,
            labelStyle: AppTypography.bodySmall(context,
                color: theme.text.withValues(alpha: 0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          maxLength: 20,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),

        AppButton(
          label: l10n.save,
          onPressed: _saving ? null : _save,
        ),

        const SizedBox(height: 28),
        Divider(color: theme.border),
        const SizedBox(height: 16),

        // ── Section B: Total score ───────────────────────────
        _sectionHeader(context, theme, l10n.points),
        const SizedBox(height: 12),
        _buildTotalScore(context, theme, profile.totalPoints),

        const SizedBox(height: 24),

        // ── Section C: Per-feature stats ─────────────────────
        _sectionHeader(context, theme, l10n.progress),
        const SizedBox(height: 12),
        _buildStatsGrid(context, theme, l10n, counters),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _sectionHeader(
      BuildContext context, AppTheme theme, String label) {
    return Text(
      label,
      style: AppTypography.bodyLarge(context,
          color: theme.text, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAvatarGrid(AppTheme theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: kAvatarPresets.length,
      itemBuilder: (context, i) {
        final selected = i == _selectedIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? theme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? theme.primary : theme.border,
                width: selected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(kAvatarPresets[i],
                style: const TextStyle(fontSize: 22)),
          ),
        );
      },
    );
  }

  Widget _buildTotalScore(
      BuildContext context, AppTheme theme, int totalPoints) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on, color: theme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            totalPoints.toString(),
            style: AppTypography.h3(context, color: theme.primary),
          ),
          const SizedBox(width: 6),
          Text(
            'pts',
            style: AppTypography.bodySmall(context,
                color: theme.primary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppTheme theme,
      AppLocalizations l10n, Map<String, int> counters) {
    final stats = [
      _StatItem(
        icon: Icons.yard,
        label: l10n.garden,
        value: counters['garden_points'] ?? 0,
        unit: l10n.achievementUnit('points'),
      ),
      _StatItem(
        icon: Icons.water,
        label: l10n.aquarium,
        value: counters['aquarium_points'] ?? 0,
        unit: l10n.achievementUnit('points'),
      ),
      _StatItem(
        icon: Icons.brush,
        label: l10n.paintingRoom,
        value: counters['pixels_painted'] ?? 0,
        unit: l10n.achievementUnit('pixels'),
      ),
      _StatItem(
        icon: Icons.music_note,
        label: l10n.musicRoom,
        value: counters['notes_changed'] ?? 0,
        unit: l10n.achievementUnit('notes'),
      ),
      _StatItem(
        icon: Icons.air,
        label: l10n.breathing,
        value: counters['breathing_total'] ?? 0,
        unit: l10n.achievementUnit('sessions'),
      ),
      _StatItem(
        icon: Icons.book_outlined,
        label: l10n.emotionDiary,
        value: counters['diary_count'] ?? 0,
        unit: l10n.achievementUnit('entries'),
      ),
      _StatItem(
        icon: Icons.check_box_outlined,
        label: l10n.tasks,
        value: counters['schedule_task_count'] ?? 0,
        unit: l10n.achievementUnit('tasks'),
      ),
      _StatItem(
        icon: Icons.bedtime_outlined,
        label: l10n.sleep,
        value: counters['sleep_log_count'] ?? 0,
        unit: l10n.achievementUnit('logs'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) => _buildStatCard(context, theme, stats[i]),
    );
  }

  Widget _buildStatCard(
      BuildContext context, AppTheme theme, _StatItem stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(stat.icon, size: 18, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.label,
                  style: AppTypography.bodySmall(context,
                      color: theme.text.withValues(alpha: 0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${stat.value} ${stat.unit}',
                  style: AppTypography.bodyMedium(context,
                      color: theme.text, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final int value;
  final String unit;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });
}
