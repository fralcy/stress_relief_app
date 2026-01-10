import 'package:hive/hive.dart';

part 'breathing_session.g.dart';

@HiveType(typeId: 18)
class BreathingSession extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String exerciseType; // '4-7-8', 'box', 'deep_belly', 'calm'

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final int cyclesCompleted;

  BreathingSession({
    required this.date,
    required this.exerciseType,
    required this.durationSeconds,
    required this.cyclesCompleted,
  });
}
