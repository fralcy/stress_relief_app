// Service tính điểm và nhận điểm
import '../../models/index.dart';
import 'data_manager.dart';

class SchedulePointsService {
  /// Tính điểm từ danh sách tasks
  /// Rule: 5 phút = 1 điểm, làm tròn xuống
  static int calculatePoints(List<ScheduleTask> tasks) {
    int totalMinutes = 0;
    for (var task in tasks) {
      if (task.isCompleted) {
        totalMinutes += task.durationInMinutes;
      }
    }
    return totalMinutes ~/ 5; // Floor division
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

  /// Claim điểm hàng ngày
  /// Returns: Số điểm nhận được (hoặc null nếu đã claim hoặc không có completed tasks)
  static Future<int?> claimDailyPoints() async {
    final dm = DataManager();
    final profile = dm.userProfile;
    final tasks = dm.scheduleTasks;

    // Check đã claim hôm nay chưa
    if (!canClaimToday(profile.lastPointsClaimDate)) {
      return null; // Đã claim rồi
    }

    // Tính điểm từ completed tasks
    final points = calculatePoints(tasks);
    if (points == 0) {
      return null; // Không có completed tasks
    }

    // Cập nhật profile
    final updatedProfile = profile.copyWith(
      currentPoints: profile.currentPoints + points,
      totalPoints: profile.totalPoints + points,
      lastPointsClaimDate: DateTime.now(),
    );
    await dm.saveUserProfile(updatedProfile);

    // Xóa tất cả completed tasks
    final remainingTasks = tasks.where((task) => !task.isCompleted).toList();
    await dm.saveScheduleTasks(remainingTasks);

    return points;
  }

  /// Tính điểm dự kiến từ completed tasks (chưa claim)
  static int getPendingPoints(List<ScheduleTask> tasks) {
    return calculatePoints(tasks);
  }
}
