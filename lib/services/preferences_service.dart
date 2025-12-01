import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String _keyLanguage = 'user_language';
  static const String _keyHouseholdMembers = 'household_members';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDarkMode = 'dark_mode';

  // Language preferences
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  // Household members preferences
  static Future<void> saveHouseholdMembers(List<String> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyHouseholdMembers, members);
  }

  static Future<List<String>?> getHouseholdMembers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyHouseholdMembers);
  }

  // Onboarding completion status
  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Dark mode preference
  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Clear all preferences (for testing/reset)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}