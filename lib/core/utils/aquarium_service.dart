import 'dart:math';
import '../constants/fish_config.dart';
import '../../models/aquarium_progress.dart';

/// Data class for food particle animation
class FoodParticleData {
  final double targetX;
  final double targetY;
  final double delay;

  FoodParticleData({
    required this.targetX,
    required this.targetY,
    required this.delay,
  });
}

class AquariumService {
  // Tính trạng thái của bể cá dựa trên lastFed
  // Status: 'growing' (đang trong cycle < 20h), 'ready' (đã đủ 20h, có thể feed lại)
  static String calculateFishStatus(DateTime lastFed) {
    final now = DateTime.now();
    final elapsed = now.difference(lastFed);
    
    // Nếu đã đủ 20h → ready to feed again
    if (elapsed.inHours >= FishConfigs.cycleHours) {
      return 'ready';
    }
    
    // Đang trong quá trình grow
    return 'growing';
  }
  
  // Tính phần trăm hoàn thành cycle (0-100)
  static int calculateCycleProgress(DateTime lastFed) {
    final now = DateTime.now();
    final elapsed = now.difference(lastFed);
    
    // Cycle là 20h
    final progress = (elapsed.inMinutes / (FishConfigs.cycleHours * 60)) * 100;
    
    return progress.clamp(0, 100).toInt();
  }
  
  // Tính tổng điểm có thể claim (có thể claim bất cứ lúc nào, không cần đợi đủ 20h)
  static int calculateClaimablePoints(List<Fish> fishes, DateTime lastFed, DateTime? lastClaimed) {
    int totalPoints = 0;
    
    final now = DateTime.now();
    // Tính từ lần claim cuối (hoặc từ lúc feed nếu chưa claim lần nào)
    final startTime = lastClaimed ?? lastFed;
    final elapsed = now.difference(startTime);
    
    // Tính số giờ đã trôi qua kể từ lần claim cuối, max 20h
    final hoursElapsed = (elapsed.inMinutes / 60).clamp(0, FishConfigs.cycleHours.toDouble());
    
    // Tính điểm cho từng con cá
    for (var fish in fishes) {
      final config = FishConfigs.getConfig(fish.type);
      if (config != null) {
        totalPoints += (config.pointsPerHour * hoursElapsed).toInt();
      }
    }
    
    return totalPoints;
  }
  
  // Check có thể feed không (phải đợi đủ 20h)
  static bool canFeed(DateTime lastFed) {
    return calculateFishStatus(lastFed) == 'ready';
  }
  
  // Random vị trí cho cá trong bể (giới hạn trong bounds)
  static Map<String, double> getRandomPosition(double maxWidth, double maxHeight) {
    final random = Random();
    
    // Để cá không nằm sát mép, giữ margin 10%
    final marginX = maxWidth * 0.1;
    final marginY = maxHeight * 0.1;
    
    return {
      'x': marginX + random.nextDouble() * (maxWidth - 2 * marginX),
      'y': marginY + random.nextDouble() * (maxHeight - 2 * marginY),
    };
  }
  
  // Random scale nhẹ cho cá (0.95 - 1.05)
  static double getRandomScale() {
    final random = Random();
    return 0.95 + random.nextDouble() * 0.1;
  }

  // Generate food particles for feeding animation
  static List<FoodParticleData> generateFoodParticles({
    required double containerSize,
    int particleCount = 8,
    double spreadRatio = 0.6,
    double maxDelay = 0.4,
  }) {
    final particles = <FoodParticleData>[];
    final centerX = containerSize / 2;
    final centerY = containerSize / 2;
    final random = Random();

    for (int i = 0; i < particleCount; i++) {
      final offsetX = centerX + (random.nextDouble() - 0.5) * containerSize * spreadRatio;
      final offsetY = centerY + (random.nextDouble() - 0.5) * containerSize * spreadRatio;
      final delay = random.nextDouble() * maxDelay;

      particles.add(FoodParticleData(
        targetX: offsetX,
        targetY: offsetY,
        delay: delay,
      ));
    }

    return particles;
  }

  // ==================== DEBUG METHODS ====================

  /// [DEBUG] Skip the 20-hour feed cycle by moving lastFed backwards
  static DateTime debugSkipFeedCycle(DateTime currentLastFed) {
    return currentLastFed.subtract(const Duration(hours: FishConfigs.cycleHours));
  }

  /// [DEBUG] Maximize claimable points by moving lastClaimed backwards
  static DateTime? debugMaximizeClaimablePoints(
    DateTime lastFed,
    DateTime? currentLastClaimed,
  ) {
    final baseTime = currentLastClaimed ?? lastFed;
    return baseTime.subtract(const Duration(hours: FishConfigs.cycleHours));
  }
}