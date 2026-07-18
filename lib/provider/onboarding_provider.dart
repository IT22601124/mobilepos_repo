import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _onboardingKey = 'has_completed_onboarding';
  
  bool _hasCompletedOnboarding = false;
  bool _isLoaded = false;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoaded => _isLoaded;

  OnboardingProvider() {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
