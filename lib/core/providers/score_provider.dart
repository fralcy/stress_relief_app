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

  /// Update points và notify listeners
  Future<void> updatePoints(int newPoints) async {
    _profile = _profile.copyWith(
      currentPoints: newPoints,
      totalPoints: _profile.totalPoints + (newPoints - _profile.currentPoints),
    );
    await DataManager().saveUserProfile(_profile);
    notifyListeners(); // ← KEY: Trigger rebuild!
  }

  /// Add points (helper method)
  Future<void> addPoints(int points) async {
    final newTotal = _profile.currentPoints + points;
    await updatePoints(newTotal);
  }

  /// Subtract points (helper method)
  Future<void> subtractPoints(int points) async {
    final newTotal = (_profile.currentPoints - points).clamp(0, double.infinity).toInt();
    await updatePoints(newTotal);
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