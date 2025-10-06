import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_en.dart';

/// Delegate để Flutter biết cách load localization
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support tiếng Việt và tiếng Anh
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Load tương ứng với locale
    switch (locale.languageCode) {
      case 'vi':
        return AppLocalizationsVi();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsVi(); // Default tiếng Việt
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}