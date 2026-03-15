import 'package:hive/hive.dart';

part 'aquarium_progress.g.dart';

// Model cho cá trong bể
@HiveType(typeId: 13)
class Fish {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final DateTime? lastFed; // null = chưa từng được cho ăn (đói)

  @HiveField(2)
  final DateTime? lastClaimed; // null = chưa từng nhận xu từ con cá này

  Fish({
    required this.type,
    this.lastFed,
    this.lastClaimed,
  });

  Fish copyWith({
    String? type,
    DateTime? lastFed,
    DateTime? lastClaimed,
    bool clearLastClaimed = false,
  }) {
    return Fish(
      type: type ?? this.type,
      lastFed: lastFed ?? this.lastFed,
      lastClaimed: clearLastClaimed ? null : (lastClaimed ?? this.lastClaimed),
    );
  }
}

// Model cho tiến trình mini-game nuôi cá
@HiveType(typeId: 5)
class AquariumProgress {
  @HiveField(0)
  final List<Fish> fishes; // Danh sách cá trong bể, tối đa 10 con

  @HiveField(2)
  final int earnings; // Tổng điểm kiếm được (field index giữ nguyên để tương thích dữ liệu cũ)

  AquariumProgress({
    required this.fishes,
    required this.earnings,
  });

  AquariumProgress copyWith({
    List<Fish>? fishes,
    int? earnings,
  }) {
    return AquariumProgress(
      fishes: fishes ?? this.fishes,
      earnings: earnings ?? this.earnings,
    );
  }
}
