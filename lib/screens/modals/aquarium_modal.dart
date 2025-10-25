import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/asset_loader.dart';
import '../../models/scene_models.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal mini-game nuôi cá (với image assets)
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

    // Initialize fish shop with localized names (update names each time in case language changes)
    if (_fishShop.isEmpty) {
      _fishShop = {
        'betta': FishData(
          fishType: 'betta',
          name: l10n.betta,
          pointsPerHour: 5,
          price: 100,
          owned: 1,
        ),
        'guppy': FishData(
          fishType: 'guppy',
          name: l10n.guppy,
          pointsPerHour: 3,
          price: 80,
          owned: 2,
        ),
        'neon': FishData(
          fishType: 'neon',
          name: l10n.neonTetra,
          pointsPerHour: 4,
          price: 90,
          owned: 0,
        ),
        'molly': FishData(
          fishType: 'molly',
          name: l10n.molly,
          pointsPerHour: 3,
          price: 75,
          owned: 0,
        ),
        'cory': FishData(
          fishType: 'cory',
          name: l10n.cory,
          pointsPerHour: 4,
          price: 85,
          owned: 0,
        ),
        'platy': FishData(
          fishType: 'platy',
          name: l10n.platy,
          pointsPerHour: 3,
          price: 70,
          owned: 0,
        ),
      };
    } else {
      // Update names when language changes
      _fishShop = _fishShop.map((key, fish) {
        String newName = fish.name;
        switch (key) {
          case 'betta': newName = l10n.betta; break;
          case 'guppy': newName = l10n.guppy; break;
          case 'neon': newName = l10n.neonTetra; break;
          case 'molly': newName = l10n.molly; break;
          case 'cory': newName = l10n.cory; break;
          case 'platy': newName = l10n.platy; break;
        }
        return MapEntry(key, fish.copyWith(name: newName));
      });
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
        
        // Bể cá với background image
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.border, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Background bể cá
                  Positioned.fill(
                    child: Image.asset(
                      AssetLoader.getTankAsset(SceneSet.defaultSet),
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Các con cá (lấy từ owned fish)
                  ..._buildOwnedFishPositions(),
                ],
              ),
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

  List<Widget> _buildOwnedFishPositions() {
    // Lấy các cá đã sở hữu
    final ownedFish = _fishShop.entries
        .where((entry) => entry.value.owned > 0)
        .toList();
    
    if (ownedFish.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return [
        Center(
          child: Text(
            '${l10n.noFishYet} ${l10n.buyFishBelow}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ];
    }

    // Mock positions cho demo
    final List<Map<String, dynamic>> positions = [
      {'left': 0.15, 'top': 0.2},
      {'left': 0.6, 'top': 0.15},
      {'left': 0.3, 'top': 0.45},
      {'left': 0.7, 'top': 0.5},
      {'left': 0.1, 'top': 0.7},
      {'left': 0.55, 'top': 0.75},
    ];

    List<Widget> fishWidgets = [];
    int posIndex = 0;

    for (var entry in ownedFish) {
      for (int i = 0; i < entry.value.owned && posIndex < positions.length; i++) {
        final pos = positions[posIndex];
        fishWidgets.add(
          Positioned(
            left: MediaQuery.of(context).size.width * (pos['left'] as double),
            top: MediaQuery.of(context).size.width * (pos['top'] as double),
            child: Image.asset(
              AssetLoader.getFishAsset(entry.value.fishType),
              width: 48,
              height: 48,
            ),
          ),
        );
        posIndex++;
      }
    }

    return fishWidgets;
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
          // Ảnh cá (thay vì emoji)
          Image.asset(
            AssetLoader.getFishAsset(fish.fishType),
            width: 48,
            height: 48,
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
          
          // Nút [ - ]  owned  [ + ]
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
                '${fish.owned}',
                style: TextStyle(
                  fontSize: 16,
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

/// Data class cho từng loại cá
class FishData {
  final String fishType; // Thêm fishType để load asset
  final String name;
  final int pointsPerHour;
  final int price;
  final int owned;

  FishData({
    required this.fishType,
    required this.name,
    required this.pointsPerHour,
    required this.price,
    required this.owned,
  });

  FishData copyWith({
    String? fishType,
    String? name,
    int? pointsPerHour,
    int? price,
    int? owned,
  }) {
    return FishData(
      fishType: fishType ?? this.fishType,
      name: name ?? this.name,
      pointsPerHour: pointsPerHour ?? this.pointsPerHour,
      price: price ?? this.price,
      owned: owned ?? this.owned,
    );
  }
}