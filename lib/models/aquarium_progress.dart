// Model cho cá trong bể
class Fish{
  final String type;      // Loại cá
  final int hunger;       // Độ đói (0-100)
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
  }){
    return Fish(
      type: type ?? this.type,
      hunger: hunger ?? this.hunger,
      pointsPerHours: pointsPerHours ?? this.pointsPerHours,
    );
  }
}
// Model cho tiến trình mini-game nuôi cá
class AquariumProgress {
  final List<Fish> fishes; // Danh sách cá trong bể, tối đa 10 con
  final DateTime lastFed; // Thời điểm cho ăn lần cuối
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