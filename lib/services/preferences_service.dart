import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class PreferencesService {
  static const String _keyLanguage = 'user_language';
  static const String _keyHouseholdMembers = 'household_members';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyMemberIcon = 'member_icon_';
  static const String _keyMemberImageBytes = 'member_image_bytes_';
  static const String _keyMemberColor = 'member_color_';

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

  // Member icon preferences
  static Future<void> saveMemberIcon(String memberId, IconData icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyMemberIcon$memberId', icon.codePoint);
  }

  static Future<IconData?> getMemberIcon(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final codePoint = prefs.getInt('$_keyMemberIcon$memberId');
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return null;
  }

  // Member image bytes preferences (stored as base64)
  static Future<void> saveMemberImageBytes(String memberId, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyMemberImageBytes$memberId', base64Encode(bytes));
  }

  static Future<Uint8List?> getMemberImageBytes(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final base64String = prefs.getString('$_keyMemberImageBytes$memberId');
    if (base64String != null) {
      return base64Decode(base64String);
    }
    return null;
  }

  // Member color preferences
  static Future<void> saveMemberColor(String memberId, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyMemberColor$memberId', color.value);
  }

  static Future<Color?> getMemberColor(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('$_keyMemberColor$memberId');
    if (colorValue != null) {
      return Color(colorValue);
    }
    return null;
  }

  // Clear all preferences (for testing/reset)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}