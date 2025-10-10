import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/scene_models.dart';

/// Navigation footer - 5 phòng cố định
/// 
/// Layout: 5 buttons ngang, active = secondary, inactive = primary
/// Order: Paint - Garden - Living (center) - Aquarium - Music
class NavMenuFooter extends StatelessWidget {
  final SceneType currentScene;
  final ValueChanged<SceneType> onSceneChanged;

  const NavMenuFooter({
    super.key,
    required this.currentScene,
    required this.onSceneChanged,
  });

  // Thứ tự hiển thị: center-focused (Living Room ở giữa)
  static const List<SceneType> _displayOrder = [
    SceneType.paintingRoom,  // 🎨 Trái
    SceneType.garden,        // 🌱
    SceneType.livingRoom,    // 🏠 GIỮA (main hub)
    SceneType.aquarium,      // 🐟
    SceneType.musicRoom,     // 🎵 Phải
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _displayOrder.map((scene) {
          final isActive = scene == currentScene;
          return _buildNavButton(
            icon: _getSceneIcon(scene),
            isActive: isActive,
            onPressed: () => onSceneChanged(scene),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final bgColor = isActive ? AppColors.secondary : AppColors.primary;
    
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 32,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }

  IconData _getSceneIcon(SceneType scene) {
    switch (scene) {
      case SceneType.livingRoom:
        return Icons.home;
      case SceneType.garden:
        return Icons.local_florist;
      case SceneType.aquarium:
        return Icons.water;
      case SceneType.paintingRoom:
        return Icons.palette;
      case SceneType.musicRoom:
        return Icons.music_note;
    }
  }
}