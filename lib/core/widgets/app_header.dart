import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/app_colors.dart';
import '../providers/score_provider.dart';
import '../utils/data_manager.dart';
import '../../screens/modals/settings_modal.dart';

/// Header cố định ở top màn hình
/// 
/// Layout: [Scene Shop] [Coin: 1234] [Settings]
/// - Background: transparent
/// - Items: primary bg, background text
class AppHeader extends StatefulWidget {
  final VoidCallback onSceneShopPressed;

  const AppHeader({
    super.key,
    required this.onSceneShopPressed,
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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Cập nhật điểm số mỗi lần rebuild
    final currentPoints = context.watch<ScoreProvider>().currentPoints;
    
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            icon: Icons.landscape,
            onPressed: widget.onSceneShopPressed,
            theme: theme,
          ),
          _buildCoinDisplay(currentPoints, theme),
          _buildHeaderButton(
            icon: Icons.settings,
            onPressed: () => SettingsModal.show(context),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    required AppTheme theme,
  }) {
    return Material(
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
    );
  }

  Widget _buildCoinDisplay(int points, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, size: 24, color: theme.background),
          const SizedBox(width: 8),
          Text(
            points.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.background,
            ),
          ),
        ],
      ),
    );
  }
}