// Service tính điểm và nhận điểm
import '../../models/index.dart';

class SchedulePointsService {
  /// Tính điểm từ danh sách tasks
  /// Rule: 2 phút = 1 điểm, làm tròn xuống
  static int calculatePoints(List<ScheduleTask> tasks) {
    int totalMinutes = 0;
    for (var task in tasks) {
      if (task.isCompleted) {
        totalMinutes += task.durationInMinutes;
      }
    }
    return totalMinutes ~/ 2;
  }

  /// Kiểm tra có thể claim điểm hôm nay không
  static bool canClaimToday(DateTime? lastClaimDate) {
    if (lastClaimDate == null) return true;
    
    final now = DateTime.now();
    final lastClaim = DateTime(
      lastClaimDate.year,
      lastClaimDate.month,
      lastClaimDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    
    return today.isAfter(lastClaim);
  }

  /// Tính điểm dự kiến từ completed tasks (chưa claim)
  static int getPendingPoints(List<ScheduleTask> tasks) {
    return calculatePoints(tasks);
  }
  
  // ← XÓA method claimDailyPoints() vì không dùng nữa
}