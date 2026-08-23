import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _soundEnabledKey = 'sound_enabled';

  bool _isSoundEnabled = true;
  bool _isLoaded = false;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isLoaded => _isLoaded;

  AppSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<void> toggleSound() async {
    await setSoundEnabled(!_isSoundEnabled);
  }
}
