import 'package:flutter/material.dart';
import '../utils/locale_storage.dart';

/// Provider để quản lý locale state
class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get currentLocale => _currentLocale;

  /// Load locale từ LocaleStorage
  void _loadLocale() {
    final savedLocale = LocaleStorage.getLocale();
    _currentLocale = savedLocale;
    notifyListeners();
  }

  /// Đổi locale và lưu vào storage
  void setLocale(String languageCode) {
    if (languageCode == _currentLocale.languageCode) return;

    final newLocale = Locale(languageCode);
    _currentLocale = newLocale;
    LocaleStorage.saveLocale(newLocale);
    
    notifyListeners();
  }
}