/// Service for breathing exercise logic
/// Provides exercise configurations, phase detection, and animation calculations
class BreathingExerciseService {
  static final BreathingExerciseService _instance =
      BreathingExerciseService._internal();
  factory BreathingExerciseService() => _instance;
  BreathingExerciseService._internal();

  /// Exercise configurations: {name: {inhale, hold, exhale, pause}}
  /// All durations in seconds
  static const Map<String, Map<String, int>> exercises = {
    '4-7-8': {'inhale': 4, 'hold': 7, 'exhale': 8, 'pause': 0},
    'box': {'inhale': 4, 'hold': 4, 'exhale': 4, 'pause': 4},
    'deep_belly': {'inhale': 5, 'hold': 2, 'exhale': 6, 'pause': 0},
    'calm': {'inhale': 4, 'hold': 2, 'exhale': 6, 'pause': 2},
  };

  /// Get exercise configuration by type
  Map<String, int> getExerciseConfig(String exerciseType) {
    return exercises[exerciseType] ?? exercises['4-7-8']!;
  }

  /// Calculate total cycle duration in seconds
  int getCycleDuration(String exerciseType) {
    final config = getExerciseConfig(exerciseType);
    return config.values.reduce((a, b) => a + b);
  }

  /// Get current phase and progress based on elapsed seconds in cycle
  /// Returns {'phase': 'inhale'|'hold'|'exhale'|'pause', 'progress': 0.0-1.0}
  Map<String, dynamic> getCurrentPhase(
      String exerciseType, int elapsedInCycle) {
    final config = getExerciseConfig(exerciseType);
    int acc = 0;

    final inhale = config['inhale']!;
    final hold = config['hold']!;
    final exhale = config['exhale']!;
    final pause = config['pause']!;

    // Inhale phase
    acc += inhale;
    if (elapsedInCycle < acc) {
      return {
        'phase': 'inhale',
        'progress': inhale > 0 ? elapsedInCycle / inhale : 1.0
      };
    }

    // Hold phase (skip if duration is 0)
    if (hold > 0) {
      acc += hold;
      if (elapsedInCycle < acc) {
        return {
          'phase': 'hold',
          'progress': (elapsedInCycle - (acc - hold)) / hold
        };
      }
    }

    // Exhale phase
    acc += exhale;
    if (elapsedInCycle < acc) {
      return {
        'phase': 'exhale',
        'progress': exhale > 0 ? (elapsedInCycle - (acc - exhale)) / exhale : 1.0
      };
    }

    // Pause phase (skip if duration is 0)
    return {
      'phase': 'pause',
      'progress': pause > 0 ? (elapsedInCycle - acc) / pause : 1.0
    };
  }

  /// Get mascot scale for breathing animation
  /// Returns scale factor: 1.0 (normal) to 1.3 (expanded)
  double getMascotScale(String phase, double progress) {
    switch (phase) {
      case 'inhale':
        return 1.0 + (0.3 * progress); // 1.0 → 1.3
      case 'exhale':
        return 1.3 - (0.3 * progress); // 1.3 → 1.0
      case 'hold':
        return 1.3; // Stay expanded
      case 'pause':
      default:
        return 1.0; // Stay normal
    }
  }
}
