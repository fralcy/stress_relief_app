import 'package:hive/hive.dart';

part 'aquarium_progress.g.dart';

// Model cho cá trong bể
@HiveType(typeId: 13)
class Fish {
  @HiveField(0)
  final String type;      // Loại cá
  
  @HiveField(1)
  final int hunger;       // Độ đói (0-100)
  
  @HiveField(2)
  final int pointsPerHours; // Điểm sinh ra mỗi giờ

  Fish({
    required this.type,
    required this.hunger,
    required this.pointsPerHours,
  });

  Fish copyWith({
    String? type,
    int? hunger,
    int? pointsPerHours,
  }) {
    return Fish(
      type: type ?? this.type,
      hunger: hunger ?? this.hunger,
      pointsPerHours: pointsPerHours ?? this.pointsPerHours,
    );
  }
}

// Model cho tiến trình mini-game nuôi cá
@HiveType(typeId: 5)
class AquariumProgress {
  @HiveField(0)
  final List<Fish> fishes; // Danh sách cá trong bể, tối đa 10 con
  
  @HiveField(1)
  final DateTime lastFed; // Thời điểm cho ăn lần cuối
  
  @HiveField(2)
  final int earnings; // Tổng điểm kiếm được

  AquariumProgress({
    required this.fishes,
    required this.lastFed,
    required this.earnings,
  });

  AquariumProgress copyWith({
    List<Fish>? fishes,
    DateTime? lastFed,
    int? earnings,
  }) {
    return AquariumProgress(
      fishes: fishes ?? this.fishes,
      lastFed: lastFed ?? this.lastFed,
      earnings: earnings ?? this.earnings,
    );
  }
}