import 'package:hive/hive.dart';

part 'sleep_session.g.dart';

@HiveType(typeId: 19)
class SleepSession extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final String bgmTrack;

  @HiveField(2)
  final int timerDurationMinutes;

  @HiveField(3)
  final bool completed;

  SleepSession({
    required this.startTime,
    required this.bgmTrack,
    required this.timerDurationMinutes,
    required this.completed,
  });
}
