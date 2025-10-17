import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/app_colors.dart';
import '../utils/data_manager.dart';
import '../../screens/modals/settings_modal.dart';

/// Header cố định ở top màn hình
/// 
/// Layout: [Scene Shop] [Coin: 1234] [Settings]
/// - Background: transparent
/// - Items: primary bg, background text
class AppHeader extends StatelessWidget {
  final VoidCallback onSceneShopPressed;

  const AppHeader({
    super.key,
    required this.onSceneShopPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currentPoints = DataManager().userProfile.currentPoints;
    
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            icon: Icons.landscape,
            onPressed: onSceneShopPressed,
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