import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/task.dart';
import '../models/column_data.dart';
import '../utils/routine_animation.dart';

class RoutineService {
  static const List<MaterialColor> _defaultColors = [
    Colors.green,
    Colors.purple,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];

  static List<ColumnData> initializeColumns(
    List<String> columnNames, 
    AppLocalizations l10n
  ) {
    return columnNames.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      return ColumnData(
        id: name.toLowerCase(),
        name: name + l10n.tasksSuffix,
        color: _defaultColors[index % _defaultColors.length].shade100,
        tasks: [],
        listKey: GlobalKey<AnimatedListState>(),
      );
    }).toList();
  }

  static Map<String, List<Task>> getDefaultRoutines(AppLocalizations l10n) {
    return {
      'Morning Routine': [
        Task(text: l10n.wakeUp),
        Task(text: l10n.brushTeeth),
        Task(text: l10n.getDressed),
        Task(text: l10n.eatBreakfast),
        Task(text: l10n.packBag),
      ],
      'Evening Routine': [
        Task(text: l10n.takeABath),
        Task(text: l10n.brushTeeth),
        Task(text: l10n.readABook),
        Task(text: l10n.goToSleep),
      ],
    };
  }

  static Map<String, List<Task>> initializeRoutines(
    AppLocalizations l10n, 
    Map<String, List<Task>>? existingCustomRoutines
  ) {
    final defaultRoutines = getDefaultRoutines(l10n);
    
    if (existingCustomRoutines != null) {
      // Preserve custom routines and update default ones with new language
      final result = <String, List<Task>>{};
      
      // Add updated default routines
      result.addAll(defaultRoutines);
      
      // Add back custom routines (non-default ones)
      final customRoutineCount = existingCustomRoutines.length - defaultRoutines.length;
      existingCustomRoutines.forEach((name, tasks) {
        if (!defaultRoutines.containsKey(name)) {
          result[name] = tasks; // Keep custom routines as-is
        }
      });
      
      // Debug: Print routine preservation info
      if (customRoutineCount > 0) {
        print('RoutineService: Preserved $customRoutineCount custom routines during language change');
      }
      
      return result;
    }
    
    return defaultRoutines;
  }

  static bool isDefaultRoutine(String routineName) {
    return routineName == 'Morning Routine' || routineName == 'Evening Routine';
  }

  static Map<String, RoutineAnimationSettings> getDefaultAnimations() {
    return {
      'Morning Routine': RoutineAnimationSettings(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        type: RoutineAnimation.slide,
      ),
      'Evening Routine': RoutineAnimationSettings(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        type: RoutineAnimation.fade,
      ),
    };
  }

  static Map<String, IconData> getDefaultIcons() {
    return {
      'Morning Routine': Icons.wb_sunny,
      'Evening Routine': Icons.nightlight,
    };
  }

  static ColumnData createNewColumn(
    String name, 
    AppLocalizations l10n, 
    int existingColumnsCount
  ) {
    return ColumnData(
      id: name.toLowerCase(),
      name: name + l10n.tasksSuffix,
      color: _defaultColors[existingColumnsCount % _defaultColors.length].shade100,
      tasks: [],
      listKey: GlobalKey<AnimatedListState>(),
    );
  }

  static String getLocalizedRoutineName(String routineName, AppLocalizations l10n) {
    switch (routineName) {
      case 'Morning Routine':
        return l10n.morningRoutine;
      case 'Evening Routine':
        return l10n.eveningRoutine;
      default:
        return routineName;
    }
  }

  static void updateColumnNamesWithLocalization(
    List<ColumnData> columns,
    List<String> columnNames,
    AppLocalizations l10n
  ) {
    for (int i = 0; i < columns.length && i < columnNames.length; i++) {
      // Only update the suffix, preserve the base name
      final baseName = columnNames[i];
      columns[i].name = baseName + l10n.tasksSuffix;
    }
  }
} 