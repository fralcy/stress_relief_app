import 'package:hive/hive.dart';

part 'sleep_log.g.dart';

@HiveType(typeId: 21)
class SleepLog extends HiveObject {
  @HiveField(0)
  final DateTime date; // Ngày (chỉ lấy year/month/day)

  @HiveField(1)
  final int? bedtimeMinutes; // Giờ thực tế đi ngủ (phút từ nửa đêm)

  @HiveField(2)
  final int? wakeTimeMinutes; // Giờ thực tế thức dậy (phút từ nửa đêm)

  @HiveField(3)
  final int? quality; // Chất lượng giấc ngủ (1-5)

  @HiveField(4)
  final String notes;

  SleepLog({
    required this.date,
    this.bedtimeMinutes,
    this.wakeTimeMinutes,
    this.quality,
    this.notes = '',
  });

  /// Thời lượng ngủ tính bằng phút (xử lý qua nửa đêm)
  int? get durationMinutes {
    if (bedtimeMinutes == null || wakeTimeMinutes == null) return null;
    final diff = wakeTimeMinutes! - bedtimeMinutes!;
    // Nếu thức dậy trước giờ đi ngủ => qua đêm (vd ngủ 23:00, dậy 07:00)
    return diff < 0 ? diff + 1440 : diff;
  }

  /// Thời lượng ngủ dạng giờ thập phân (dùng cho biểu đồ)
  double? get durationHours {
    final mins = durationMinutes;
    return mins != null ? mins / 60.0 : null;
  }

  SleepLog copyWith({
    DateTime? date,
    int? bedtimeMinutes,
    int? wakeTimeMinutes,
    int? quality,
    String? notes,
  }) {
    return SleepLog(
      date: date ?? this.date,
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }
}
