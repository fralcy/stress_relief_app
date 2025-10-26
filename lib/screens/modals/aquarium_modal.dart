import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/fish_config.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/aquarium_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sfx_service.dart';
import '../../models/aquarium_progress.dart';
import '../../models/scene_models.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal mini-game nuôi cá
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
  late AquariumProgress _progress;
  final List<_FishAnimationData> _fishAnimations = [];
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startAnimationTimer();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAnimationTimer() {
    // Update animation every 3 seconds
    _animationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _updateFishAnimations();
        });
      }
    });
  }

  void _updateFishAnimations() {
    final containerSize = MediaQuery.of(context).size.width;
    final fishSize = 48.0; // Fish image width
    
    for (var anim in _fishAnimations) {
      final newPos = AquariumService.getRandomPosition(
        containerSize - fishSize, 
        containerSize - fishSize,
      );
      
      // Determine if fish should flip (moving right vs left)
      final movingRight = newPos['x']! > anim.targetX;
      
      anim.oldX = anim.targetX;
      anim.targetX = newPos['x']!;
      anim.targetY = newPos['y']!;
      anim.targetScale = AquariumService.getRandomScale();
      anim.flipHorizontal = movingRight; // Flip when moving right
    }
  }

  void _loadProgress() {
    var progress = DataManager().aquariumProgress;
    
    // Nếu chưa có data → khởi tạo mặc định với 2 con betta
    progress ??= AquariumProgress(
      fishes: [
        Fish(type: 'betta'),
        Fish(type: 'betta'),
      ],
      lastFed: DateTime.now(),
      earnings: 0,
      lastClaimed: null,
    );
    
    setState(() {
      _progress = progress!;
      _initializeFishAnimations();
    });
    
    _saveProgress();
  }

  void _initializeFishAnimations() {
    _fishAnimations.clear();
    final containerSize = MediaQuery.of(context).size.width;
    final fishSize = 48.0;
    
    for (int i = 0; i < _progress.fishes.length; i++) {
      final pos = AquariumService.getRandomPosition(
        containerSize - fishSize, 
        containerSize - fishSize,
      );
      _fishAnimations.add(_FishAnimationData(
        currentX: pos['x']!,
        currentY: pos['y']!,
        targetX: pos['x']!,
        targetY: pos['y']!,
        oldX: pos['x']!,
        currentScale: 1.0,
        targetScale: 1.0,
        flipHorizontal: false,
      ));
    }
  }

  void _saveProgress() {
    DataManager().saveAquariumProgress(_progress);
  }

  void _onFeed() {
    if (!AquariumService.canFeed(_progress.lastFed)) return;
    
    setState(() {
      _progress = _progress.copyWith(
        lastFed: DateTime.now(),
        lastClaimed: null, // Reset lastClaimed khi feed mới
      );
    });
    
    _saveProgress();
    SfxService().taskComplete();
  }

  void _onClaim() {
    final claimablePoints = AquariumService.calculateClaimablePoints(
      _progress.fishes,
      _progress.lastFed,
      _progress.lastClaimed,
    );
    
    if (claimablePoints == 0) return;
    
    // Update user profile points
    final currentProfile = DataManager().userProfile;
    final updatedProfile = currentProfile.copyWith(
      currentPoints: currentProfile.currentPoints + claimablePoints,
      totalPoints: currentProfile.totalPoints + claimablePoints,
      lastPointsClaimDate: DateTime.now(),
    );
    DataManager().saveUserProfile(updatedProfile);
    
    setState(() {
      _progress = _progress.copyWith(
        earnings: _progress.earnings + claimablePoints,
        lastClaimed: DateTime.now(),
      );
    });
    
    _saveProgress();
    SfxService().reward();
  }

  void _onBuyFish(String fishType) {
    final config = FishConfigs.getConfig(fishType);
    if (config == null) return;
    
    final currentProfile = DataManager().userProfile;
    
    // Check có đủ điểm không
    if (currentProfile.currentPoints < config.price) return;
    
    // Kiểm tra max 10 con
    if (_progress.fishes.length >= 10) return;
    
    // Trừ điểm từ user profile
    final updatedProfile = currentProfile.copyWith(
      currentPoints: currentProfile.currentPoints - config.price,
    );
    DataManager().saveUserProfile(updatedProfile);
    
    setState(() {
      final newFishes = List<Fish>.from(_progress.fishes)
        ..add(Fish(type: fishType));
      
      _progress = _progress.copyWith(fishes: newFishes);
      
      // Add animation cho cá mới
      final containerSize = MediaQuery.of(context).size.width;
      final pos = AquariumService.getRandomPosition(containerSize, containerSize);
      _fishAnimations.add(_FishAnimationData(
        currentX: pos['x']!,
        currentY: pos['y']!,
        targetX: pos['x']!,
        targetY: pos['y']!,
        oldX: pos['x']!, 
        currentScale: 1.0,
        targetScale: 1.0,
        flipHorizontal: false, 
      ));
    });
    
    _saveProgress();
    SfxService().reward();
  }

  void _onSellFish(String fishType) {
    final fishIndex = _progress.fishes.indexWhere((f) => f.type == fishType);
    if (fishIndex == -1) return;
    
    final config = FishConfigs.getConfig(fishType);
    if (config != null) {
      // Hoàn lại 50% giá khi bán
      final sellPrice = (config.price * 0.5).toInt();
      final currentProfile = DataManager().userProfile;
      final updatedProfile = currentProfile.copyWith(
        currentPoints: currentProfile.currentPoints + sellPrice,
      );
      DataManager().saveUserProfile(updatedProfile);
    }
    
    setState(() {
      final newFishes = List<Fish>.from(_progress.fishes)
        ..removeAt(fishIndex);
      
      _progress = _progress.copyWith(fishes: newFishes);
      
      // Remove animation
      if (fishIndex < _fishAnimations.length) {
        _fishAnimations.removeAt(fishIndex);
      }
    });
    
    _saveProgress();
    SfxService().buttonClick();
  }



  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final currentPoints = DataManager().userProfile.currentPoints;

    // Tính toán thông tin hiển thị
    final totalFish = _progress.fishes.length;
    final totalPointsPerHour = _progress.fishes.fold<int>(
      0,
      (sum, fish) {
        final config = FishConfigs.getConfig(fish.type);
        return sum + (config?.pointsPerHour ?? 0);
      },
    );
    
    final cycleProgress = AquariumService.calculateCycleProgress(_progress.lastFed);
    final canFeed = AquariumService.canFeed(_progress.lastFed);
    final claimablePoints = AquariumService.calculateClaimablePoints(
      _progress.fishes,
      _progress.lastFed,
      _progress.lastClaimed,
    );
    
    // Tính thời gian từ lastFed
    final hoursSinceFed = DateTime.now().difference(_progress.lastFed).inHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PHẦN TRÊN: Bể cá
        _buildTankSection(
          theme,
          l10n,
          totalFish,
          totalPointsPerHour,
          hoursSinceFed,
          cycleProgress,
          canFeed,
          claimablePoints,
          currentPoints,
        ),
        
        const SizedBox(height: 16),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // PHẦN DƯỚI: Cửa hàng cá
        Expanded(
          child: SingleChildScrollView(
            child: _buildFishShop(theme, l10n, currentPoints),
          ),
        ),
      ],
    );
  }

  Widget _buildTankSection(
    AppTheme theme,
    AppLocalizations l10n,
    int totalFish,
    int totalPointsPerHour,
    int hoursSinceFed,
    int cycleProgress,
    bool canFeed,
    int claimablePoints,
    int currentPoints,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info section - simplified
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🐟 $totalFish/10 • 🪙 $totalPointsPerHour/${l10n.hour}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$currentPoints',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Cycle progress
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.lastFed} $hoursSinceFed ${l10n.hoursAgo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.text.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: cycleProgress / 100,
                    backgroundColor: theme.border,
                    valueColor: AlwaysStoppedAnimation(
                      canFeed ? Colors.green : theme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cycleProgress% - ${canFeed ? l10n.readyToFeed : "${20 - hoursSinceFed}${l10n.hoursLeft}"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: canFeed ? Colors.green : theme.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Bể cá với background image
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: canFeed ? Colors.green : theme.border,
                width: canFeed ? 3 : 2,
              ),
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
                  
                  // Các con cá với animation
                  ..._buildAnimatedFish(),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: '🍞 ${l10n.feedNow}',
                onPressed: canFeed ? _onFeed : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: '🪙 ${l10n.claimCoins} ($claimablePoints)',
                onPressed: claimablePoints > 0 ? _onClaim : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildAnimatedFish() {
    if (_progress.fishes.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '${l10n.noFishYet}\n${l10n.buyFishBelow}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ];
    }

    List<Widget> fishWidgets = [];

    for (int i = 0; i < _progress.fishes.length && i < _fishAnimations.length; i++) {
      final fish = _progress.fishes[i];
      final anim = _fishAnimations[i];
      
      fishWidgets.add(
        AnimatedPositioned(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          left: anim.targetX,
          top: anim.targetY,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            scale: anim.targetScale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(anim.flipHorizontal ? -1.0 : 1.0, 1.0),
              child: Image.asset(
                AssetLoader.getFishAsset(fish.type),
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      );
    }

    return fishWidgets;
  }

  Widget _buildFishShop(AppTheme theme, AppLocalizations l10n, int currentPoints) {
    // Đếm số lượng từng loại cá
    final Map<String, int> fishCounts = {};
    for (var fish in _progress.fishes) {
      fishCounts[fish.type] = (fishCounts[fish.type] ?? 0) + 1;
    }
    
    final isTankFull = _progress.fishes.length >= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.fishShop,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            if (isTankFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.tankFull,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // List các loại cá từ config
        ...FishConfigs.fishes.entries.map((entry) {
          final fishType = entry.key;
          final config = entry.value;
          final owned = fishCounts[fishType] ?? 0;
          
          // Get localized name
          String localizedName = config.name;
          switch (fishType) {
            case 'betta': localizedName = l10n.betta; break;
            case 'guppy': localizedName = l10n.guppy; break;
            case 'neon': localizedName = l10n.neonTetra; break;
            case 'molly': localizedName = l10n.molly; break;
            case 'cory': localizedName = l10n.cory; break;
            case 'platy': localizedName = l10n.platy; break;
          }
          
          return _buildFishCard(
            fishType,
            localizedName,
            config.pointsPerHour,
            config.price,
            owned,
            theme,
            l10n,
            currentPoints,
            isTankFull,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFishCard(
    String fishType,
    String name,
    int pointsPerHour,
    int price,
    int owned,
    AppTheme theme,
    AppLocalizations l10n,
    int currentPoints,
    bool isTankFull,
  ) {
    final canBuy = currentPoints >= price && !isTankFull;
    
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
          // Ảnh cá
          Image.asset(
            AssetLoader.getFishAsset(fishType),
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
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
                Text(
                  '🪙 $pointsPerHour/${l10n.hour}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.text.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: canBuy
                            ? Colors.amber
                            : Colors.red.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Nút [ - ]  owned  [ + ]
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: owned > 0 ? () => _onSellFish(fishType) : null,
                color: owned > 0
                    ? theme.primary
                    : theme.text.withOpacity(0.3),
              ),
              
              Text(
                '$owned ${l10n.owned}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: canBuy ? () => _onBuyFish(fishType) : null,
                color: canBuy
                    ? theme.primary
                    : theme.text.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class cho animation data
class _FishAnimationData {
  double currentX;
  double currentY;
  double targetX;
  double targetY;
  double oldX; // Track old position for flip detection
  double currentScale;
  double targetScale;
  bool flipHorizontal; // true = facing left, false = facing right

  _FishAnimationData({
    required this.currentX,
    required this.currentY,
    required this.targetX,
    required this.targetY,
    required this.oldX,
    required this.currentScale,
    required this.targetScale,
    required this.flipHorizontal,
  });
}