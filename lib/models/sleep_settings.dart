import 'package:hive/hive.dart';

part 'sleep_settings.g.dart';

@HiveType(typeId: 20)
class SleepSettings extends HiveObject {
  @HiveField(0)
  final int? bedtimeMinutes; // Minutes from midnight (e.g., 1320 = 22:00)

  @HiveField(1)
  final int? wakeTimeMinutes;

  SleepSettings({
    this.bedtimeMinutes,
    this.wakeTimeMinutes,
  });

  factory SleepSettings.initial() => SleepSettings(
        bedtimeMinutes: 1320, // 22:00
        wakeTimeMinutes: 420, // 07:00
      );

  SleepSettings copyWith({
    int? bedtimeMinutes,
    int? wakeTimeMinutes,
  }) {
    return SleepSettings(
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
    );
  }
}
