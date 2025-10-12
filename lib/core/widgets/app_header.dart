import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../screens/modals/settings_modal.dart';

/// Header cố định ở top màn hình
/// 
/// Layout: [Scene Shop] [Coin: 1234] [Settings]
/// - Background: transparent
/// - Items: primary bg, background text
class AppHeader extends StatelessWidget {
  final int coins;
  final VoidCallback onSceneShopPressed;

  const AppHeader({
    super.key,
    required this.coins,
    required this.onSceneShopPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Scene Shop Button
          _buildHeaderButton(
            icon: Icons.landscape,
            onPressed: onSceneShopPressed,
          ),
          
          // Coin Display
          _buildCoinDisplay(),
          
          // Settings Button - Opens Settings Modal
          _buildHeaderButton(
            icon: Icons.settings,
            onPressed: () => SettingsModal.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            size: 24,
            color: AppColors.background,
          ),
          const SizedBox(width: 8),
          Text(
            coins.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}