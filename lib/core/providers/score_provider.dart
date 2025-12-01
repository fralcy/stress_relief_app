import 'package:flutter/material.dart';
import '../utils/data_manager.dart';
import '../../models/user_profile.dart';

/// Provider để quản lý user profile state
class ScoreProvider extends ChangeNotifier {
  UserProfile _profile;

  ScoreProvider() : _profile = DataManager().userProfile;

  UserProfile get profile => _profile;
  int get currentPoints => _profile.currentPoints;

  /// Load profile từ DataManager
  void loadProfile() {
    _profile = DataManager().userProfile;
    notifyListeners();
  }

  /// Update current points only (for spending)
  Future<void> updateCurrentPoints(int newPoints) async {
    _profile = _profile.copyWith(
      currentPoints: newPoints,
    );
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
  }

  /// Add points (increases both current and total)
  Future<void> addPoints(int points) async {
    _profile = _profile.copyWith(
      currentPoints: _profile.currentPoints + points,
      totalPoints: _profile.totalPoints + points,
    );
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
  }

  /// Subtract points (decreases only current, not total)
  Future<void> subtractPoints(int points) async {
    final newCurrent = (_profile.currentPoints - points).clamp(0, double.infinity).toInt();
    await updateCurrentPoints(newCurrent);
  }

  /// Legacy method for backward compatibility
  Future<void> updatePoints(int newPoints) async {
    await updateCurrentPoints(newPoints);
  }

  /// Reload từ DataManager (khi cần sync)
  void refresh() {
    _profile = DataManager().userProfile;
    notifyListeners();
  }

  /// Update lastPointsClaimDate
  Future<void> updateLastClaimDate(DateTime date) async {
    _profile = _profile.copyWith(
      lastPointsClaimDate: date,
    );
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
  }
}