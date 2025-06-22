import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/task.dart';
import '../models/column_data.dart';
import '../utils/routine_animation.dart';
import '../widgets/language_dialog.dart';
import '../widgets/column_dialogs.dart';
import '../widgets/routine_drawer.dart';
import '../widgets/task_column.dart';
import '../widgets/animation_picker_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../services/routine_service.dart';
import 'add_routine_screen.dart';
import 'edit_routine_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  
  const HomeScreen({super.key, required this.onLocaleChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Configurable list of names - you can modify this list as needed
  List<String> _columnNames = ['Assaf', 'Ofir'];
  
  late List<ColumnData> columns;
  String _currentRoutine = 'Morning Routine';
  late Map<String, List<Task>> routines;
  late Map<String, IconData> routineIcons;
  late Map<String, RoutineAnimationSettings> routineAnimations;

  bool _isDarkMode = false;
  bool _isChildMode = false;
  bool _isLoadingRoutine = false;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    } else {
      _updateLocalization();
    }
  }

  void _initializeData() {
    final l10n = AppLocalizations.of(context)!;
    columns = RoutineService.initializeColumns(_columnNames, l10n);
    routines = RoutineService.initializeRoutines(l10n, null);
    routineIcons = RoutineService.getDefaultIcons();
    routineAnimations = RoutineService.getDefaultAnimations();
  }

  void _updateLocalization() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      // Update column names with new localization but preserve existing data
      RoutineService.updateColumnNamesWithLocalization(columns, _columnNames, l10n);
      // Update routines with new localization but preserve custom routines
      routines = RoutineService.initializeRoutines(l10n, routines);
    });
  }

  // Method to easily update the column names - call this to change the default columns
  void updateColumnNames(List<String> newNames) {
    setState(() {
      _columnNames = newNames;
      final l10n = AppLocalizations.of(context)!;
      columns = RoutineService.initializeColumns(_columnNames, l10n);
    });
  }

  // Dialog methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => LanguageDialog(onLocaleChange: widget.onLocaleChange),
    );
  }

  void _showAddColumnDialog() {
    showDialog(
      context: context,
      builder: (context) => AddColumnDialog(
        onAdd: (name) {
          setState(() {
            final newColumn = RoutineService.createNewColumn(
              name, 
              AppLocalizations.of(context)!, 
              columns.length
            );
            columns.add(newColumn);
            _columnNames.add(name);
          });
        },
      ),
    );
  }

  void _showEditColumnNameDialog(String columnId) {
    final column = columns.firstWhere((col) => col.id == columnId);
    showDialog(
      context: context,
      builder: (context) => EditColumnNameDialog(
        column: column,
        onSave: (newName) {
          setState(() {
            column.name = newName;
          });
        },
      ),
    );
  }

  void _showColorPicker(String columnId) {
    final column = columns.firstWhere((col) => col.id == columnId);
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        column: column,
        onColorChanged: (color) {
          setState(() {
            column.color = color;
          });
        },
      ),
    );
  }

  void _showManageColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageColumnsDialog(
        columns: columns,
        onDelete: (index) {
          setState(() {
            _columnNames.removeAt(index);
            columns.removeAt(index);
          });
          _showManageColumnsDialog();
        },
        onEdit: _showEditColumnNameDialog,
        onAddNew: _showAddColumnDialog,
      ),
    );
  }

  void _showAnimationPicker(String routineName) {
    showDialog(
      context: context,
      builder: (context) => AnimationPickerDialog(
        routineName: routineName,
        currentSettings: routineAnimations[routineName],
        onAnimationSelected: (animationType) {
          setState(() {
            routineAnimations[routineName] = RoutineAnimationSettings(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              type: animationType,
            );
          });
        },
      ),
    );
  }

  // Task management methods
  void _addTask(String columnId) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onAdd: (text) {
          setState(() {
            final column = columns.firstWhere((col) => col.id == columnId);
            final task = Task(text: text);
            final firstMarkedIndex = column.tasks.indexWhere((t) => t.isDone);
            final insertIndex = firstMarkedIndex == -1 ? column.tasks.length : firstMarkedIndex;
            column.tasks.insert(insertIndex, task);
            column.listKey.currentState?.insertItem(insertIndex);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleTask(String columnId, int index) {
    setState(() {
      final column = columns.firstWhere((col) => col.id == columnId);
      final task = column.tasks[index];
      task.isDone = !task.isDone;
      
      // Remove the task from its current position
      column.tasks.removeAt(index);
      
      // Find the new position based on completion status
      final firstMarkedIndex = column.tasks.indexWhere((t) => t.isDone);
      final insertIndex = firstMarkedIndex == -1 ? column.tasks.length : firstMarkedIndex;
      
      // Insert the task at the new position
      column.tasks.insert(insertIndex, task);
      
      // Update the list state with proper animation
      column.listKey.currentState?.removeItem(
        index,
        (context, animation) => SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildTaskCardWithDragHandle(task, columnId, insertIndex),
          ),
        ),
      );
      column.listKey.currentState?.insertItem(insertIndex);
    });
  }

  void _removeTask(String taskKey) {
    final parts = taskKey.split('_');
    final columnId = parts[0];
    final index = int.parse(parts[1]);
    
    setState(() {
      final column = columns.firstWhere((col) => col.id == columnId);
      final task = column.tasks.removeAt(index);
      column.listKey.currentState?.removeItem(
        index,
        (context, animation) => SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildTaskCardWithDragHandle(task, columnId, index),
          ),
        ),
      );
    });
  }

  // Routine management methods
  void _loadRoutine(String name) {
    setState(() {
      _isDarkMode = name == 'Evening Routine';
      _currentRoutine = name;
      _isLoadingRoutine = true;
    });

    // Clear existing tasks
    for (var column in columns) {
      column.tasks.clear();
    }

    // Add routine tasks
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        for (var column in columns) {
          for (var task in routines[name]!) {
            setState(() {
              column.tasks.add(Task(text: task.text));
            });
          }
        }
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingRoutine = false;
            });
          }
        });
      }
    });
  }

  void _clearAllTasks() {
    setState(() {
      for (var column in columns) {
        column.tasks.clear();
      }
    });
  }

  void _addNewRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoutineScreen(
          onAdd: (name, tasks, icon, animationSettings) {
            setState(() {
              routines[name] = tasks;
              routineIcons[name] = icon;
              routineAnimations[name] = animationSettings;
            });
          },
        ),
      ),
    );
  }

  void _editRoutine(String routineName) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = RoutineService.getLocalizedRoutineName(routineName, l10n);
    final isDefaultRoutine = RoutineService.isDefaultRoutine(routineName);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoutineScreen(
          routineName: routineName,
          displayName: displayName,
          tasks: routines[routineName]!,
          icon: routineIcons[routineName] ?? Icons.schedule,
          animationSettings: routineAnimations[routineName] ?? RoutineAnimationSettings(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            type: RoutineAnimation.slide,
          ),
          isDefaultRoutine: isDefaultRoutine,
          onSave: (originalName, newDisplayName, tasks, icon, animationSettings) {
            setState(() {
              String finalRoutineName;
              
              // For default routines, keep the original internal name regardless of display name changes
              if (isDefaultRoutine) {
                finalRoutineName = originalName;
              } else {
                // For custom routines, use the new display name as the routine name
                finalRoutineName = newDisplayName;
                
                // Remove old routine if name changed
                if (originalName != finalRoutineName) {
                  routines.remove(originalName);
                  routineIcons.remove(originalName);
                  routineAnimations.remove(originalName);
                }
              }
              
              // Add/update routine with new values
              routines[finalRoutineName] = tasks;
              routineIcons[finalRoutineName] = icon;
              routineAnimations[finalRoutineName] = animationSettings;
              
              // Update current routine if it was the one being edited
              if (_currentRoutine == originalName) {
                _currentRoutine = finalRoutineName;
              }
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.routineUpdated),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _deleteRoutine(String name) {
    setState(() {
      routines.remove(name);
      routineIcons.remove(name);
      routineAnimations.remove(name);
    });
  }

  void _toggleChildMode() {
    final l10n = AppLocalizations.of(context)!;
    if (_isChildMode) {
      // Generate a random number between 1 and 10
      final random = DateTime.now().millisecondsSinceEpoch % 10 + 1;
      final numberWords = {
        1: 'one', 2: 'two', 3: 'three', 4: 'four', 5: 'five',
        6: 'six', 7: 'seven', 8: 'eight', 9: 'nine', 10: 'ten'
      };

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.exitChildMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.pleaseEnterNumber(numberWords[random]!)),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.enterNumber,
                ),
                onSubmitted: (value) {
                  if (int.tryParse(value) == random) {
                    Navigator.pop(context);
                    setState(() {
                      _isChildMode = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.incorrectNumber),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _isChildMode = true;
      });
    }
  }

  // Widget builders
  Widget _buildTaskCardWithDragHandle(Task task, String columnId, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _toggleTask(columnId, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (bool? value) => _toggleTask(columnId, index),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.text,
                  style: TextStyle(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? Colors.grey : null,
                    fontSize: 18,
                  ),
                ),
              ),
              if (!_isChildMode && !task.isDone) 
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTaskWrapper(Widget child, int index) {
    final animationType = routineAnimations[_currentRoutine]?.type ?? RoutineAnimation.slide;
    final duration = routineAnimations[_currentRoutine]?.duration ?? const Duration(milliseconds: 500);
    
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        switch (animationType) {
          case RoutineAnimation.slide:
            return Transform.translate(
              offset: Offset((1.0 - value) * 200, 0),
              child: child,
            );
          case RoutineAnimation.fade:
            return Opacity(
              opacity: value,
              child: child,
            );
          case RoutineAnimation.scale:
            return Transform.scale(
              scale: value,
              child: child,
            );
          case RoutineAnimation.bounce:
            return Transform.translate(
              offset: Offset(0, (1.0 - value) * 100),
              child: child,
            );
          case RoutineAnimation.rotate:
            return Transform.rotate(
              angle: (1.0 - value) * 0.5,
              child: child,
            );
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedTheme(
      duration: const Duration(milliseconds: 500),
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: _showLanguageDialog,
              tooltip: l10n.language,
            ),
            if (!_isChildMode) IconButton(
              icon: const Icon(Icons.view_column),
              onPressed: _showManageColumnsDialog,
              tooltip: l10n.manageColumns,
            ),
            IconButton(
              icon: Icon(
                _isChildMode ? Icons.child_care : Icons.child_care_outlined,
                color: _isChildMode ? Colors.orange : null,
              ),
              onPressed: _toggleChildMode,
              tooltip: _isChildMode ? l10n.exitChildMode : l10n.enterChildMode,
            ),
          ],
        ),
        drawer: _isChildMode ? null : RoutineDrawer(
          routines: routines,
          routineIcons: routineIcons,
          onRoutineSelected: _loadRoutine,
          onAnimationPicker: _showAnimationPicker,
          onDeleteRoutine: _deleteRoutine,
          onEditRoutine: _editRoutine,
          onAddNewRoutine: _addNewRoutine,
          onClearAllTasks: _clearAllTasks,
          getLocalizedRoutineName: (name) => RoutineService.getLocalizedRoutineName(name, l10n),
        ),
        body: Row(
          children: columns.map((column) => TaskColumn(
            column: column,
            isDarkMode: _isDarkMode,
            isChildMode: _isChildMode,
            isLoadingRoutine: _isLoadingRoutine,
            onToggleTask: (taskKey) => _toggleTask(column.id, int.parse(taskKey)),
            onRemoveTask: _removeTask,
            onEditColumnName: _showEditColumnNameDialog,
            onShowColorPicker: _showColorPicker,
            onAddTask: _addTask,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final task = column.tasks.removeAt(oldIndex);
                column.tasks.insert(newIndex, task);
              });
            },
            buildAnimatedTaskWrapper: _buildAnimatedTaskWrapper,
            buildTaskCardWithDragHandle: _buildTaskCardWithDragHandle,
          )).toList(),
        ),
      ),
    );
  }
} 