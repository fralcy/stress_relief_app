import 'package:hive/hive.dart';

part 'aquarium_progress.g.dart';

// Model cho cá trong bể
@HiveType(typeId: 13)
class Fish {
  @HiveField(0)
  final String type;      // Loại cá

  Fish({
    required this.type,
  });


  Fish copyWith({
    String? type,
  }) {
    return Fish(
      type: type ?? this.type,
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

  @HiveField(3)
  final DateTime? lastClaimed; // Thời điểm nhận điểm lần cuối

  AquariumProgress({
    required this.fishes,
    required this.lastFed,
    required this.earnings,
    this.lastClaimed,
  });

  AquariumProgress copyWith({
    List<Fish>? fishes,
    DateTime? lastFed,
    int? earnings,
    DateTime? lastClaimed,
  }) {
    return AquariumProgress(
      fishes: fishes ?? this.fishes,
      lastFed: lastFed ?? this.lastFed,
      earnings: earnings ?? this.earnings,
      lastClaimed: lastClaimed ?? this.lastClaimed,
    );
  }
}