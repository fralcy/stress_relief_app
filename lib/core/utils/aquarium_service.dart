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
  // Kiểm tra cá có đói không (chưa từng được cho ăn, hoặc đã qua 20h)
  static bool isHungry(Fish fish) {
    if (fish.lastFed == null) return true;
    return DateTime.now().difference(fish.lastFed!).inHours >= FishConfigs.cycleHours;
  }

  // Tính % cycle đã hoàn thành của từng con cá (0-100)
  static int calculateFishCycleProgress(Fish fish) {
    if (fish.lastFed == null) return 100; // Chưa cho ăn = đói = 100%
    final elapsed = DateTime.now().difference(fish.lastFed!);
    final progress = (elapsed.inMinutes / (FishConfigs.cycleHours * 60)) * 100;
    return progress.clamp(0, 100).toInt();
  }

  // Tính số xu có thể nhận từ một con cá
  static int calculateFishClaimablePoints(Fish fish) {
    if (fish.lastFed == null) return 0; // Chưa từng được cho ăn → không có điểm

    final config = FishConfigs.getConfig(fish.type);
    if (config == null) return 0;

    final now = DateTime.now();
    final startTime = fish.lastClaimed ?? fish.lastFed!;
    final elapsed = now.difference(startTime);

    // Capped at 20h
    final hoursElapsed = (elapsed.inMinutes / 60).clamp(0, FishConfigs.cycleHours.toDouble());
    return (config.pointsPerHour * hoursElapsed).toInt();
  }

  // Tổng xu có thể nhận từ toàn bộ cá
  static int calculateTotalClaimablePoints(List<Fish> fishes) {
    return fishes.fold(0, (sum, fish) => sum + calculateFishClaimablePoints(fish));
  }

  // Cho một con cá ăn → trả về Fish mới với lastFed = now
  static Fish feedFish(Fish fish) {
    return fish.copyWith(
      lastFed: DateTime.now(),
      clearLastClaimed: true, // Reset lastClaimed khi feed mới
    );
  }

  // Nhận xu từ một con cá → trả về Fish mới với lastClaimed = now
  static Fish claimFish(Fish fish) {
    return fish.copyWith(lastClaimed: DateTime.now());
  }

  // Duration cho AnimatedPositioned: cá đói → chậm, cá no → bình thường
  static Duration getFishMovementDuration(Fish fish) {
    return isHungry(fish)
        ? const Duration(milliseconds: 5500)
        : const Duration(milliseconds: 2000);
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

  // Generate food particles cho animation khi cho ăn
  // centerX/centerY: tọa độ trung tâm con cá được cho ăn trong tank
  static List<FoodParticleData> generateFoodParticles({
    required double centerX,
    required double centerY,
    double containerSize = 0,
    int particleCount = 6,
    double spreadRadius = 40,
    double maxDelay = 0.35,
  }) {
    final particles = <FoodParticleData>[];
    final random = Random();

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final radius = random.nextDouble() * spreadRadius;
      final offsetX = centerX + cos(angle) * radius;
      final offsetY = centerY + sin(angle) * radius * 0.4; // dẹt theo chiều Y
      final delay = random.nextDouble() * maxDelay;

      particles.add(FoodParticleData(
        targetX: offsetX.clamp(0, containerSize > 0 ? containerSize : double.infinity),
        targetY: offsetY.clamp(0, containerSize > 0 ? containerSize : double.infinity),
        delay: delay,
      ));
    }

    return particles;
  }

  // ==================== DEBUG METHODS ====================

  /// [DEBUG] Cho tất cả cá trở về trạng thái đói (lastFed - 20h)
  static List<Fish> debugSkipAllFeedCycles(List<Fish> fishes) {
    return fishes.map((fish) {
      final base = fish.lastFed ?? DateTime.now();
      return fish.copyWith(
        lastFed: base.subtract(const Duration(hours: FishConfigs.cycleHours)),
      );
    }).toList();
  }

  /// [DEBUG] Maximize claimable points cho tất cả cá
  static List<Fish> debugMaximizeAllClaimablePoints(List<Fish> fishes) {
    return fishes.map((fish) {
      final base = fish.lastFed ?? DateTime.now();
      return fish.copyWith(
        lastFed: base,
        lastClaimed: base.subtract(const Duration(hours: FishConfigs.cycleHours)),
        clearLastClaimed: false,
      );
    }).toList();
  }
}
