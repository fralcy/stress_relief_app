import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../../models/sleep_settings.dart';

/// Service for sleep guide logic
/// Provides contextual tips and breathing exercise suggestions based on sleep schedule
class SleepGuideService {
  static final SleepGuideService _instance = SleepGuideService._internal();
  factory SleepGuideService() => _instance;
  SleepGuideService._internal();

  /// Convert TimeOfDay to minutes since midnight
  int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// Convert minutes to TimeOfDay
  TimeOfDay minutesToTimeOfDay(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  /// Get contextual sleep tip based on current time vs bedtime
  /// Returns appropriate tip string from localization
  String getSleepTip(AppLocalizations l10n, SleepSettings settings) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    if (settings.bedtimeMinutes == null) {
      return l10n.sleepTipSetBedtime;
    }

    final diff = settings.bedtimeMinutes! - currentMinutes;
    // Handle past midnight cases (e.g., bedtime 22:00, current 01:00)
    final normalizedDiff = diff < -720 ? diff + 1440 : diff;

    if (normalizedDiff > 60) {
      return l10n.sleepTipEarly; // More than 1 hour before bedtime
    } else if (normalizedDiff > 0) {
      return l10n.sleepTipWindDown; // Within 1 hour of bedtime
    } else if (normalizedDiff > -60) {
      return l10n.sleepTipLate; // Up to 1 hour past bedtime
    } else {
      return l10n.sleepTipVeryLate; // More than 1 hour past bedtime
    }
  }

  /// Determine whether to suggest breathing exercise
  /// Returns true if within 60 min of bedtime or up to 2 hours past
  bool shouldSuggestBreathing(SleepSettings settings) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    if (settings.bedtimeMinutes == null) return false;

    final diff = settings.bedtimeMinutes! - currentMinutes;
    final normalizedDiff = diff < -720 ? diff + 1440 : diff;

    // Suggest breathing if within 60 min of bedtime or up to 2 hours past
    return normalizedDiff <= 60 && normalizedDiff > -120;
  }
}
