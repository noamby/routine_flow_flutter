import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/task.dart';

class PreferencesService {
  static const String _keyLanguage = 'user_language';
  static const String _keyHouseholdMembers = 'household_members';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyMemberIcon = 'member_icon_';
  static const String _keyMemberImageBytes = 'member_image_bytes_';
  static const String _keyMemberColor = 'member_color_';
  static const String _keyCustomRoutines = 'custom_routines';
  static const String _keyRoutineIcons = 'routine_icons';
  static const String _keyRoutineAnimations = 'routine_animations';
  static const String _keyColumnTasks = 'column_tasks_';
  static const String _keyCurrentRoutine = 'current_routine';
  static const String _keyColumnColors = 'column_colors';

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

  // ============ ROUTINE PERSISTENCE ============

  // Save custom routines (excluding default Morning/Evening routines)
  static Future<void> saveCustomRoutines(Map<String, List<Task>> routines) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Filter out default routines - only save custom ones
    final customRoutines = <String, List<Map<String, dynamic>>>{};
    routines.forEach((name, tasks) {
      if (name != 'Morning Routine' && name != 'Evening Routine') {
        customRoutines[name] = tasks.map((t) => t.toJson()).toList();
      }
    });
    
    await prefs.setString(_keyCustomRoutines, jsonEncode(customRoutines));
  }

  // Load custom routines
  static Future<Map<String, List<Task>>?> getCustomRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final routinesJson = prefs.getString(_keyCustomRoutines);
    
    if (routinesJson == null) return null;
    
    try {
      final decoded = jsonDecode(routinesJson) as Map<String, dynamic>;
      final routines = <String, List<Task>>{};
      
      decoded.forEach((name, tasksJson) {
        final tasks = (tasksJson as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList();
        routines[name] = tasks;
      });
      
      return routines;
    } catch (e) {
      print('Error loading custom routines: $e');
      return null;
    }
  }

  // Save routine icons
  static Future<void> saveRoutineIcons(Map<String, IconData> icons) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert IconData to codePoints for storage
    final iconsMap = <String, int>{};
    icons.forEach((name, icon) {
      // Only save icons for custom routines
      if (name != 'Morning Routine' && name != 'Evening Routine') {
        iconsMap[name] = icon.codePoint;
      }
    });
    
    await prefs.setString(_keyRoutineIcons, jsonEncode(iconsMap));
  }

  // Load routine icons
  static Future<Map<String, IconData>?> getRoutineIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final iconsJson = prefs.getString(_keyRoutineIcons);
    
    if (iconsJson == null) return null;
    
    try {
      final decoded = jsonDecode(iconsJson) as Map<String, dynamic>;
      final icons = <String, IconData>{};
      
      decoded.forEach((name, codePoint) {
        icons[name] = IconData(codePoint as int, fontFamily: 'MaterialIcons');
      });
      
      return icons;
    } catch (e) {
      print('Error loading routine icons: $e');
      return null;
    }
  }

  // Save routine animations (type only - duration/curve are standard)
  static Future<void> saveRoutineAnimations(Map<String, int> animationTypes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoutineAnimations, jsonEncode(animationTypes));
  }

  // Load routine animations
  static Future<Map<String, int>?> getRoutineAnimations() async {
    final prefs = await SharedPreferences.getInstance();
    final animationsJson = prefs.getString(_keyRoutineAnimations);
    
    if (animationsJson == null) return null;
    
    try {
      final decoded = jsonDecode(animationsJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error loading routine animations: $e');
      return null;
    }
  }

  // Save tasks for a specific column (member)
  static Future<void> saveColumnTasks(String columnId, String routineName, List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyColumnTasks${routineName}_$columnId';
    final tasksJson = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(key, jsonEncode(tasksJson));
  }

  // Load tasks for a specific column
  static Future<List<Task>?> getColumnTasks(String columnId, String routineName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyColumnTasks${routineName}_$columnId';
    final tasksJson = prefs.getString(key);
    
    if (tasksJson == null) return null;
    
    try {
      final decoded = jsonDecode(tasksJson) as List;
      return decoded.map((t) => Task.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading column tasks: $e');
      return null;
    }
  }

  // Save all column tasks at once (for efficiency)
  static Future<void> saveAllColumnTasks(String routineName, Map<String, List<Task>> columnTasks) async {
    final prefs = await SharedPreferences.getInstance();
    
    final allTasks = <String, List<Map<String, dynamic>>>{};
    columnTasks.forEach((columnId, tasks) {
      allTasks[columnId] = tasks.map((t) => t.toJson()).toList();
    });
    
    final key = '$_keyColumnTasks$routineName';
    await prefs.setString(key, jsonEncode(allTasks));
  }

  // Load all column tasks at once
  static Future<Map<String, List<Task>>?> getAllColumnTasks(String routineName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyColumnTasks$routineName';
    final tasksJson = prefs.getString(key);
    
    if (tasksJson == null) return null;
    
    try {
      final decoded = jsonDecode(tasksJson) as Map<String, dynamic>;
      final columnTasks = <String, List<Task>>{};
      
      decoded.forEach((columnId, tasksData) {
        final tasks = (tasksData as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList();
        columnTasks[columnId] = tasks;
      });
      
      return columnTasks;
    } catch (e) {
      print('Error loading all column tasks: $e');
      return null;
    }
  }

  // Save current routine name
  static Future<void> saveCurrentRoutine(String routineName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentRoutine, routineName);
  }

  // Load current routine name
  static Future<String?> getCurrentRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentRoutine);
  }

  // Save column colors
  static Future<void> saveColumnColors(Map<String, int> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColumnColors, jsonEncode(colors));
  }

  // Load column colors
  static Future<Map<String, Color>?> getColumnColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colorsJson = prefs.getString(_keyColumnColors);
    
    if (colorsJson == null) return null;
    
    try {
      final decoded = jsonDecode(colorsJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, Color(value as int)));
    } catch (e) {
      print('Error loading column colors: $e');
      return null;
    }
  }
}