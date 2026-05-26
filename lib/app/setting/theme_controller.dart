import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_pref.dart';

class ThemeController extends ChangeNotifier {
  late final AppPreferences _appPreferences;
  late bool _darkModeEnabled;

  ThemeController({required SharedPreferences prefs}) {
    _appPreferences = AppPreferences(prefs);
    _darkModeEnabled = _appPreferences.getDarkModeEnabled();
  }

  bool get darkModeEnabled => _darkModeEnabled;

  ThemeMode get themeMode =>
      _darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkModeEnabled(bool enabled) async {
    if (_darkModeEnabled == enabled) return;

    _darkModeEnabled = enabled;
    notifyListeners();
    await _appPreferences.setDarkModeEnabled(enabled);
  }
}
