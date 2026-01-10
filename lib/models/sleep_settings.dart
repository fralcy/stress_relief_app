import 'package:hive/hive.dart';

part 'sleep_settings.g.dart';

@HiveType(typeId: 20)
class SleepSettings extends HiveObject {
  @HiveField(0)
  final int? bedtimeMinutes; // Minutes from midnight (e.g., 1320 = 22:00)

  @HiveField(1)
  final int? wakeTimeMinutes;

  @HiveField(2)
  final int defaultTimerMinutes;

  SleepSettings({
    this.bedtimeMinutes,
    this.wakeTimeMinutes,
    this.defaultTimerMinutes = 30,
  });

  factory SleepSettings.initial() => SleepSettings(
        bedtimeMinutes: 1320, // 22:00
        wakeTimeMinutes: 420, // 07:00
        defaultTimerMinutes: 30,
      );

  SleepSettings copyWith({
    int? bedtimeMinutes,
    int? wakeTimeMinutes,
    int? defaultTimerMinutes,
  }) {
    return SleepSettings(
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      defaultTimerMinutes: defaultTimerMinutes ?? this.defaultTimerMinutes,
    );
  }
}
