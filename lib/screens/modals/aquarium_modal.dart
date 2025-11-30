import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/fish_config.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/aquarium_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/providers/score_provider.dart';
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

class _AquariumModalState extends State<AquariumModal> with TickerProviderStateMixin {
  late AquariumProgress _progress;
  final List<_FishAnimationData> _fishAnimations = [];
  Timer? _animationTimer;

  // Animation controllers cho effects
  AnimationController? _feedAnimationController;
  AnimationController? _claimAnimationController;
  AnimationController? _borderPulseController;

  bool _showFeedParticles = false;
  bool _showClaimCoins = false;
  int _claimedPoints = 0;

  // Lưu trữ thông tin particles để tránh tính toán lại mỗi frame
  final List<FoodParticleData> _foodParticles = [];

  // Debug mode state
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startAnimationTimer();
    _checkDebugMode();
    
    // Initialize animation controllers
    _feedAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // 3 giây cho thức ăn rơi chậm
    );
    
    _claimAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _borderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _feedAnimationController?.dispose();
    _claimAnimationController?.dispose();
    _borderPulseController?.dispose();
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

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) {
      setState(() {
        _isDebugMode = isDebug;
      });
    }
  }

  Future<void> _debugSkipFeedCycle() async {
    if (!_isDebugMode) return;

    final newLastFed = AquariumService.debugSkipFeedCycle(_progress.lastFed);

    setState(() {
      _progress = _progress.copyWith(lastFed: newLastFed);
    });
    _saveProgress();

    SfxService().buttonClick();
  }

  Future<void> _debugMaxPoints() async {
    if (!_isDebugMode) return;

    final newLastClaimed = AquariumService.debugMaximizeClaimablePoints(
      _progress.lastFed,
      _progress.lastClaimed,
    );

    setState(() {
      _progress = _progress.copyWith(lastClaimed: newLastClaimed);
    });
    _saveProgress();

    SfxService().buttonClick();
  }

  void _onFeed() {
    if (!AquariumService.canFeed(_progress.lastFed)) return;

    // Khởi tạo particles một lần duy nhất
    _initializeFoodParticles();

    setState(() {
      _progress = _progress.copyWith(
        lastFed: DateTime.now(),
        lastClaimed: null, // Reset lastClaimed khi feed mới
      );
      _showFeedParticles = true;
    });

    _feedAnimationController?.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showFeedParticles = false;
        });
      }
    });

    _saveProgress();
    SfxService().taskComplete();
  }

  void _initializeFoodParticles() {
    _foodParticles.clear();
    final containerSize = MediaQuery.of(context).size.width;

    // Sử dụng service để generate particles
    _foodParticles.addAll(
      AquariumService.generateFoodParticles(containerSize: containerSize),
    );
  }

  void _onClaim() async {
    final claimablePoints = AquariumService.calculateClaimablePoints(
      _progress.fishes,
      _progress.lastFed,
      _progress.lastClaimed,
    );
    
    if (claimablePoints == 0) return;
    
    // Update user profile points
    await context.read<ScoreProvider>().addPoints(claimablePoints);

    setState(() {
      _progress = _progress.copyWith(
        earnings: _progress.earnings + claimablePoints,
        lastClaimed: DateTime.now(),
      );
      _claimedPoints = claimablePoints;
      _showClaimCoins = true;
    });
    
    _claimAnimationController?.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showClaimCoins = false;
        });
      }
    });
    
    _saveProgress();
    SfxService().reward();
  }  void _onBuyFish(String fishType) async {
    final config = FishConfigs.getConfig(fishType);
    if (config == null) return;
    
    final currentProfile = DataManager().userProfile;
    
    // Check có đủ điểm không
    if (currentProfile.currentPoints < config.price) return;
    
    // Kiểm tra max 10 con
    if (_progress.fishes.length >= 10) return;
    
    // Trừ điểm từ user profile
    await context.read<ScoreProvider>().subtractPoints(config.price);
    
    setState(() {
      final newFishes = List<Fish>.from(_progress.fishes)
        ..add(Fish(type: fishType));
      
      _progress = _progress.copyWith(fishes: newFishes);
      
      // Add animation cho cá mới với smooth entry
      final containerSize = MediaQuery.of(context).size.width;
      final pos = AquariumService.getRandomPosition(containerSize, containerSize);
      _fishAnimations.add(_FishAnimationData(
        currentX: pos['x']!,
        currentY: pos['y']!,
        targetX: pos['x']!,
        targetY: pos['y']!,
        oldX: pos['x']!, 
        currentScale: 0.0, // Start from scale 0
        targetScale: 1.0,  // Grow to normal size
        flipHorizontal: false, 
      ));
    });
    
    _saveProgress();
    SfxService().reward();
  }

  void _onSellFish(String fishType) async {
    final fishIndex = _progress.fishes.indexWhere((f) => f.type == fishType);
    if (fishIndex == -1) return;
    
    final config = FishConfigs.getConfig(fishType);
    if (config != null) {
      // Hoàn lại 50% giá khi bán
      final sellPrice = (config.price * 0.5).toInt();
      await context.read<ScoreProvider>().addPoints(sellPrice);
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
    final currentPoints = context.watch<ScoreProvider>().currentPoints;

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
          child: AnimatedBuilder(
            animation: _borderPulseController!,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: canFeed 
                        ? Color.lerp(Colors.green, Colors.lightGreenAccent, _borderPulseController!.value)!
                        : theme.border,
                    width: canFeed ? 2 + (_borderPulseController!.value * 2) : 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canFeed ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3 * _borderPulseController!.value),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: child,
              );
            },
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
                  
                  // Feed particles animation
                  if (_showFeedParticles)
                    ..._buildFeedParticles(),
                    
                  // Claim coins animation
                  if (_showClaimCoins)
                    _buildClaimCoinsEffect(),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Buttons - improved layout to prevent text overflow
        Column(
          children: [
            // Feed button - full width
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: '🍞 ${l10n.feedNow}',
                onPressed: canFeed ? _onFeed : null,
              ),
            ),
            const SizedBox(height: 8),
            // Claim button - full width with better text handling
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: claimablePoints > 0 
                    ? '🪙 ${l10n.claimCoins} ($claimablePoints)'
                    : '🪙 ${l10n.claimCoins}',
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
  
  List<Widget> _buildFeedParticles() {
    // Sử dụng particles đã được khởi tạo sẵn để tránh tính toán lại mỗi frame
    if (_foodParticles.isEmpty) return [];

    return _foodParticles.map((particle) {
      return AnimatedBuilder(
        animation: _feedAnimationController!,
        builder: (context, child) {
          // Tính progress với delay
          final rawProgress = _feedAnimationController!.value - particle.delay;
          final adjustedProgress = particle.delay < 1.0
              ? (rawProgress / (1.0 - particle.delay)).clamp(0.0, 1.0)
              : rawProgress.clamp(0.0, 1.0);

          // Vị trí Y: rơi từ -20 xuống vị trí đích
          final startY = -20.0;
          final endY = particle.targetY;
          final currentY = startY + (endY - startY) * adjustedProgress;

          // Chỉ hiển thị khi đã đến lượt (sau delay)
          if (_feedAnimationController!.value < particle.delay) {
            return const SizedBox.shrink();
          }

          return Positioned(
            left: particle.targetX,
            top: currentY,
            child: Opacity(
              opacity: (1.0 - adjustedProgress * 0.3).clamp(0.0, 1.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.brown,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
  
  Widget _buildClaimCoinsEffect() {
    return Center(
      child: AnimatedBuilder(
        animation: _claimAnimationController!,
        builder: (context, child) {
          final progress = _claimAnimationController!.value;
          
          return Transform.translate(
            offset: Offset(0, -progress * 50), // Move up
            child: Opacity(
              opacity: 1.0 - progress,
              child: Transform.scale(
                scale: 1.0 + (progress * 0.5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '+$_claimedPoints 🪙',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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

        // Debug section
        if (_isDebugMode) ...[
          const SizedBox(height: 16),
          Divider(color: theme.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),
          Text(
            'DEBUG MODE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugSkipFeedCycle,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Skip Cycle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugMaxPoints,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Max Points'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
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