import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkTheme';
  bool _isDarkTheme = false;
  bool _isInitialized = false;

  bool get isDarkTheme => _isDarkTheme;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkTheme = prefs.getBool(_themeKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    await _setTheme(!_isDarkTheme);
  }

  Future<void> setDarkTheme() async {
    await _setTheme(true);
  }

  Future<void> setLightTheme() async {
    await _setTheme(false);
  }

  Future<void> _setTheme(bool isDark) async {
    if (_isDarkTheme == isDark) return;

    try {
      _isDarkTheme = isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkTheme);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      // Revert if saving failed
      _isDarkTheme = !isDark;
      notifyListeners();
    }
  }
}
