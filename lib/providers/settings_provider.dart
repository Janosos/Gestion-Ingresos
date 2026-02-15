import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _startWeekOnSunday = false;
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark

  bool get startWeekOnSunday => _startWeekOnSunday;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _startWeekOnSunday = prefs.getBool('startWeekOnSunday') ?? false;
    final isDark = prefs.getBool('isDarkMode') ?? true; // Default true
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setStartWeekOnSunday(bool value) async {
    _startWeekOnSunday = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('startWeekOnSunday', value);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }
}
