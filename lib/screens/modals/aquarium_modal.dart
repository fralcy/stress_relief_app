import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal mini-game nuôi cá (static mockup)
class AquariumModal extends StatefulWidget {
  const AquariumModal({super.key});

  @override
  State<AquariumModal> createState() => _AquariumModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.aquarium,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const AquariumModal(),
    );
  }
}

class _AquariumModalState extends State<AquariumModal> {
  // Mock data cho cá
  Map<String, FishData> _fishShop = {};

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    // Initialize fish shop with localized names
    if (_fishShop.isEmpty) {
      _fishShop = {
        'goldfish': FishData(
          icon: '🐠',
          name: l10n.goldfish,
          pointsPerHour: 3,
          price: 100,
          owned: 2,
        ),
        'clownfish': FishData(
          icon: '🐡',
          name: l10n.clownfish,
          pointsPerHour: 3,
          price: 150,
          owned: 3,
        ),
      };
    }

    // Tính tổng
    final totalFish = _fishShop.values.fold<int>(0, (sum, fish) => sum + fish.owned);
    final totalPointsPerHour = _fishShop.values.fold<int>(
      0, 
      (sum, fish) => sum + (fish.pointsPerHour * fish.owned),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PHẦN TRÊN: Bể cá
        _buildTankSection(theme, l10n, totalFish, totalPointsPerHour),
        
        const SizedBox(height: 16),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // PHẦN DƯỚI: Cửa hàng cá
        Expanded(
          child: SingleChildScrollView(
            child: _buildFishShop(theme, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildTankSection(AppTheme theme, AppLocalizations l10n, int totalFish, int totalPointsPerHour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🐟 $totalFish ${l10n.fish}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            Text(
              '💰 $totalPointsPerHour/${l10n.hour} (${totalFish > 0 ? totalFish : 6}/10 ${l10n.fish})',
              style: TextStyle(
                fontSize: 14,
                color: theme.text,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '${l10n.lastFed} 2 ${l10n.hoursAgo}',
          style: TextStyle(
            fontSize: 12,
            color: theme.text.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bể cá (vuông/chữ nhật static)
        AspectRatio(
          aspectRatio: 1.2,
          child: Container(
            decoration: BoxDecoration(
              // Màu xanh nước biển nhạt
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF87CEEB).withOpacity(0.3),
                  const Color(0xFF4682B4).withOpacity(0.5),
                ],
              ),
              border: Border.all(color: theme.border, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Nền cát/đá dưới đáy
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355).withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('🪨', style: TextStyle(fontSize: 20)),
                        Text('🌿', style: TextStyle(fontSize: 20)),
                        Text('🪨', style: TextStyle(fontSize: 20)),
                        Text('🌱', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                
                // Mock cá bơi (static positions)
                ..._buildMockFishPositions(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Feed button
        Center(
          child: AppButton(
            label: '🍞 ${l10n.feedNow}',
            onPressed: () {
              // TODO: implement feeding logic
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMockFishPositions() {
    // Mock vị trí các con cá (static)
    final positions = [
      {'left': 20.0, 'top': 30.0, 'icon': '🐠'},
      {'left': 100.0, 'top': 60.0, 'icon': '🐡'},
      {'left': 180.0, 'top': 40.0, 'icon': '🐠'},
      {'left': 50.0, 'top': 90.0, 'icon': '🐡'},
      {'left': 150.0, 'top': 100.0, 'icon': '🐠'},
    ];

    return positions.map((pos) {
      return Positioned(
        left: pos['left'] as double,
        top: pos['top'] as double,
        child: Text(
          pos['icon'] as String,
          style: const TextStyle(fontSize: 24),
        ),
      );
    }).toList();
  }

  Widget _buildFishShop(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fishShop,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 12),
        
        // List các loại cá
        ..._fishShop.entries.map((entry) {
          return _buildFishCard(entry.key, entry.value, theme, l10n);
        }).toList(),
      ],
    );
  }

  Widget _buildFishCard(String fishType, FishData fish, AppTheme theme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border.all(color: theme.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon cá
          Text(
            fish.icon,
            style: const TextStyle(fontSize: 32),
          ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fish.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
                Text(
                  '💰 ${fish.pointsPerHour}/${l10n.hour}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.text.withOpacity(0.7),
                  ),
                ),
                Text(
                  '${l10n.price}: 💎 ${fish.price}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.text.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Nút [ - ]  2 owned  [ + ]
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: fish.owned > 0 ? () {
                  setState(() {
                    _fishShop[fishType] = fish.copyWith(owned: fish.owned - 1);
                  });
                } : null,
                color: fish.owned > 0 ? theme.primary : theme.text.withOpacity(0.3),
              ),
              
              Text(
                '${fish.owned} ${l10n.owned}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    _fishShop[fishType] = fish.copyWith(owned: fish.owned + 1);
                  });
                },
                color: theme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mock data model cho cá
class FishData {
  final String icon;
  final String name;
  final int pointsPerHour;
  final int price;
  final int owned;

  FishData({
    required this.icon,
    required this.name,
    required this.pointsPerHour,
    required this.price,
    required this.owned,
  });

  FishData copyWith({
    String? icon,
    String? name,
    int? pointsPerHour,
    int? price,
    int? owned,
  }) {
    return FishData(
      icon: icon ?? this.icon,
      name: name ?? this.name,
      pointsPerHour: pointsPerHour ?? this.pointsPerHour,
      price: price ?? this.price,
      owned: owned ?? this.owned,
    );
  }
}