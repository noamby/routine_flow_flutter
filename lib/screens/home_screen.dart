import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/column_data.dart';
import '../utils/routine_animation.dart';
import '../widgets/language_dialog.dart';
import '../widgets/column_dialogs.dart';
import '../widgets/routine_drawer.dart';
import '../widgets/task_column.dart';
import '../widgets/animation_picker_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/light_switch_widget.dart';
import '../widgets/home/routine_tab_view.dart';
import '../widgets/home/routine_column_view.dart';
import '../widgets/home/member_avatar_widget.dart';
import '../widgets/home/routine_column_header.dart';
import '../widgets/home/enhanced_task_card.dart';
import '../widgets/dialogs/avatar_icon_picker_dialog.dart';
import '../widgets/falling_icons_overlay.dart';
import '../services/routine_service.dart';
import '../services/preferences_service.dart';
import '../services/kiosk_service.dart';
import '../services/audio_service.dart';
import 'add_routine_screen.dart';
import 'edit_routine_screen.dart';
import 'manage_household_screen.dart';
import 'onboarding/tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final Function(bool) onDarkModeChange;
  final List<String>? initialMembers;

  const HomeScreen({
    super.key,
    required this.onLocaleChange,
    required this.onDarkModeChange,
    this.initialMembers,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Configurable list of household member names - you can modify this list as needed
  late List<String> _memberNames;

  // Member icons - stores the selected icon for each column
  Map<String, IconData> _memberIcons = {};

  // Member custom images - stores custom image paths (mobile) or base64 (web)
  Map<String, String> _memberImages = {};

  // Member image bytes for web rendering
  Map<String, Uint8List> _memberImageBytes = {};

  final ImagePicker _picker = ImagePicker();

  // Global key for scaffold to access drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tab controller for mobile view
  late TabController _tabController;

  late List<ColumnData> columns;
  String _currentRoutine = 'Morning Routine';
  late Map<String, List<Task>> routines;
  late Map<String, IconData> routineIcons;
  late Map<String, RoutineAnimationSettings> routineAnimations;


  bool _isChildMode = false;
  bool _isLoadingRoutine = false;
  bool _forceTabView = false; // Force tab view even on wide screens

  bool _isInitialized = false;
  Locale? _currentLocale;

  // Controller for falling icons animation (Instagram-style celebration)
  final FallingIconsController _fallingIconsController = FallingIconsController();

  @override
  void initState() {
    super.initState();
    // Initialize member names from saved preferences or use defaults
    _memberNames = widget.initialMembers ?? ['Assaf', 'Ofir'];
    _tabController = TabController(length: _memberNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fallingIconsController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberAvatars() async {
    // Load from both old format (for backwards compatibility) and new PreferencesService format
    final prefs = await SharedPreferences.getInstance();

    // First try old format
    final imagesJson = prefs.getString('member_images');
    if (imagesJson != null) {
      final loadedImages = Map<String, String>.from(
        (jsonDecode(imagesJson) as Map).cast<String, String>()
      );

      setState(() {
        _memberImages = loadedImages;

        // For web, decode base64 strings back to bytes
        if (kIsWeb) {
          for (var entry in loadedImages.entries) {
            try {
              _memberImageBytes[entry.key] = base64Decode(entry.value);
            } catch (e) {
              print('Error decoding image for ${entry.key}: $e');
            }
          }
        }
      });
    }

    // Now load from PreferencesService format (from onboarding)
    for (int i = 0; i < _memberNames.length; i++) {
      final memberId = 'member_$i';
      final columnId = columns.isNotEmpty && i < columns.length ? columns[i].id : memberId;

      // Load icon
      final icon = await PreferencesService.getMemberIcon(memberId);
      if (icon != null) {
        setState(() {
          _memberIcons[columnId] = icon;
        });
      }

      // Load image bytes
      final imageBytes = await PreferencesService.getMemberImageBytes(memberId);
      if (imageBytes != null) {
        setState(() {
          _memberImageBytes[columnId] = imageBytes;
          _memberImages[columnId] = base64Encode(imageBytes);
        });
      }

      // Load color
      final color = await PreferencesService.getMemberColor(memberId);
      if (color != null && i < columns.length) {
        setState(() {
          columns[i].color = color;
        });
      }
    }
  }

  // ============ PERSISTENCE METHODS ============

  /// Save all routine data to persistent storage
  Future<void> _saveRoutineData() async {
    await PreferencesService.saveCustomRoutines(routines);
    await PreferencesService.saveRoutineIcons(routineIcons);
    
    // Save animation types as integers
    final animationTypes = <String, int>{};
    routineAnimations.forEach((name, settings) {
      animationTypes[name] = settings.type.index;
    });
    await PreferencesService.saveRoutineAnimations(animationTypes);
    
    print('Routine data saved successfully');
  }

  /// Save current task state for all columns
  Future<void> _saveCurrentTasks() async {
    final columnTasks = <String, List<Task>>{};
    for (var column in columns) {
      columnTasks[column.id] = column.tasks;
    }
    await PreferencesService.saveAllColumnTasks(_currentRoutine, columnTasks);
    await PreferencesService.saveCurrentRoutine(_currentRoutine);
    print('Tasks saved for routine: $_currentRoutine');
  }

  /// Save column colors
  Future<void> _saveColumnColors() async {
    final colors = <String, int>{};
    for (var column in columns) {
      colors[column.id] = column.color.value;
    }
    await PreferencesService.saveColumnColors(colors);
  }

  /// Load all saved routine data
  Future<void> _loadRoutineData() async {
    // Load custom routines
    final customRoutines = await PreferencesService.getCustomRoutines();
    if (customRoutines != null && customRoutines.isNotEmpty) {
      setState(() {
        routines.addAll(customRoutines);
      });
      print('Loaded ${customRoutines.length} custom routines');
    }

    // Load routine icons
    final savedIcons = await PreferencesService.getRoutineIcons();
    if (savedIcons != null) {
      setState(() {
        routineIcons.addAll(savedIcons);
      });
    }

    // Load routine animations
    final savedAnimations = await PreferencesService.getRoutineAnimations();
    if (savedAnimations != null) {
      setState(() {
        savedAnimations.forEach((name, typeIndex) {
          if (typeIndex >= 0 && typeIndex < RoutineAnimation.values.length) {
            routineAnimations[name] = RoutineAnimationSettings(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              type: RoutineAnimation.values[typeIndex],
            );
          }
        });
      });
    }

    // Load last used routine
    final savedRoutine = await PreferencesService.getCurrentRoutine();
    if (savedRoutine != null && routines.containsKey(savedRoutine)) {
      _currentRoutine = savedRoutine;
    }

    // Load column colors
    final savedColors = await PreferencesService.getColumnColors();
    if (savedColors != null) {
      setState(() {
        for (var column in columns) {
          if (savedColors.containsKey(column.id)) {
            column.color = savedColors[column.id]!;
          }
        }
      });
    }

    // Load saved tasks for current routine
    await _loadSavedTasks();
  }

  /// Load saved tasks for the current routine
  Future<void> _loadSavedTasks() async {
    final savedTasks = await PreferencesService.getAllColumnTasks(_currentRoutine);
    if (savedTasks != null && savedTasks.isNotEmpty) {
      setState(() {
        for (var column in columns) {
          if (savedTasks.containsKey(column.id)) {
            column.tasks.clear();
            column.tasks.addAll(savedTasks[column.id]!);
          }
        }
      });
      print('Loaded saved tasks for routine: $_currentRoutine');
    }
  }

  Future<void> _saveMemberAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_images', jsonEncode(_memberImages));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);

    if (!_isInitialized) {
      _initializeData();
      _loadMemberAvatars(); // Load saved avatars after columns are initialized
      _currentLocale = currentLocale;
      _isInitialized = true;
    } else if (_currentLocale != currentLocale) {
      // Only update localization if locale actually changed
      _currentLocale = currentLocale;
      _updateLocalization();
    }
    // If only theme changed (not locale), do nothing - don't reload tasks
  }

  void _initializeData() {
    final l10n = AppLocalizations.of(context)!;
    columns = RoutineService.initializeColumns(_memberNames, l10n);
    routines = RoutineService.initializeRoutines(l10n, null);
    routineIcons = RoutineService.getDefaultIcons();
    routineAnimations = RoutineService.getDefaultAnimations();

    // Load saved data asynchronously, then update UI
    _loadRoutineData().then((_) {
      // Only load default tasks if no saved tasks were loaded
      if (columns.every((col) => col.tasks.isEmpty)) {
        // Load the default Morning Routine tasks - add ALL tasks to ALL columns
        if (routines[_currentRoutine] != null) {
          final tasks = routines[_currentRoutine]!;
          setState(() {
            for (var column in columns) {
              for (var task in tasks) {
                column.tasks.add(Task(text: task.text));
              }
            }
          });
        }
      }
    });
  }

  void _updateLocalization() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      // Update member names with new localization but preserve existing data
      RoutineService.updateColumnNamesWithLocalization(columns, _memberNames, l10n);
      // Update routines with new localization but preserve custom routines
      routines = RoutineService.initializeRoutines(l10n, routines);

      // If current routine is a default routine, reload its tasks with new language
      if (RoutineService.isDefaultRoutine(_currentRoutine)) {
        final updatedTasks = routines[_currentRoutine] ?? [];
        for (var column in columns) {
          column.tasks.clear();
          // Add ALL tasks to each column
          for (var task in updatedTasks) {
            column.tasks.add(task);
          }
        }
      }
    });
  }

  // Method to easily update the member names - call this to change the default household members
  void updateMemberNames(List<String> newNames) {
    setState(() {
      _memberNames = newNames;
      final l10n = AppLocalizations.of(context)!;
      columns = RoutineService.initializeColumns(_memberNames, l10n);
      // Recreate tab controller with new length
      _tabController.dispose();
      _tabController = TabController(length: _memberNames.length, vsync: this);
    });
  }

  // Dialog methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => LanguageDialog(onLocaleChange: widget.onLocaleChange),
    );
  }

  void _changeLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    await PreferencesService.saveLanguage(languageCode);
    widget.onLocaleChange(newLocale);
  }

  void _showAddMemberDialog() {
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
            _memberNames.add(name);
          });
        },
      ),
    );
  }

  void _showEditMemberNameDialog(String columnId) {
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
          _saveColumnColors(); // Persist color changes
        },
      ),
    );
  }

  void _showIconPicker(String columnId) {
    final column = columns.firstWhere((col) => col.id == columnId);
    final columnIndex = columns.indexOf(column);
    final hasCustomImage = _memberImages.containsKey(columnId) || _memberImageBytes.containsKey(columnId);

    showDialog(
      context: context,
      builder: (context) => AvatarIconPickerDialog(
        memberColor: column.color,
        currentIcon: _memberIcons[columnId],
        hasCustomImage: hasCustomImage,
        onIconSelected: (icon) async {
          setState(() {
            _memberIcons[columnId] = icon;
            // Clear custom image if icon selected
            _memberImages.remove(columnId);
            _memberImageBytes.remove(columnId);
          });
          // Save to both formats for compatibility
          await _saveMemberAvatars();
          await PreferencesService.saveMemberIcon('member_$columnIndex', icon);
        },
        onImageSelected: (bytes) async {
          if (kIsWeb) {
            setState(() {
              _memberImageBytes[columnId] = bytes;
              _memberImages[columnId] = base64Encode(bytes);
              _memberIcons.remove(columnId);
            });
          } else {
            // For mobile: save to file system
            final directory = await getApplicationDocumentsDirectory();
            final fileName = 'avatar_${columnId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(bytes);

            setState(() {
              _memberImages[columnId] = file.path;
              _memberImageBytes[columnId] = bytes;
              _memberIcons.remove(columnId);
            });
          }
          // Save to both formats for compatibility
          await _saveMemberAvatars();
          await PreferencesService.saveMemberImageBytes('member_$columnIndex', bytes);
        },
      ),
    );
  }

  void _openManageHouseholdScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageHouseholdScreen(
          columns: columns,
          memberNames: _memberNames,
          memberIcons: _memberIcons,
          memberImages: _memberImages,
          memberImageBytes: _memberImageBytes,
          onSave: (newMemberNames, newColumns, newIcons, newImages, newImageBytes) async {
            setState(() {
              _memberNames = newMemberNames;
              columns = newColumns;
              _memberIcons = newIcons;
              _memberImages = newImages;
              _memberImageBytes = newImageBytes;

              // Recreate tab controller with new count
              _tabController.dispose();
              _tabController = TabController(length: columns.length, vsync: this);
            });

            // Save all changes to preferences
            await PreferencesService.saveHouseholdMembers(_memberNames);
            await _saveMemberAvatars();
            await _saveColumnColors();
            await _saveCurrentTasks(); // Save tasks for new member configuration
          },
        ),
      ),
    );
  }

  void _openTutorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorialScreen(
          onCompleted: () {
            Navigator.pop(context);
          },
          isFromMenu: true, // Don't reset onboarding status
          canGoBack: false,
        ),
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
          _saveRoutineData(); // Persist animation changes
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
          _saveCurrentTasks(); // Persist task changes
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleTask(String columnId, int index) {
    final column = columns.firstWhere((col) => col.id == columnId);
    final task = column.tasks[index];

    // Toggle the task status
    final wasNotDone = !task.isDone;
    task.isDone = !task.isDone;

    // Trigger celebration animation when task is completed (with all emojis)
    if (task.isDone && wasNotDone) {
      final emojis = task.allEmojis;
      if (emojis.isNotEmpty) {
        _fallingIconsController.triggerAnimationWithMultipleIcons(emojis);
      }
    }

    // Check if all tasks in THIS column are now completed
    if (task.isDone && wasNotDone && column.tasks.isNotEmpty) {
      final columnAllDone = column.tasks.every((t) => t.isDone);
      if (columnAllDone) {
        // Play a random celebration sound
        debugPrint('🎉 Column complete! Playing celebration sound...');
        AudioService().playCompletionSound();
        
        // Delay the trophy animation so it comes after the task animation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _fallingIconsController.triggerZoomCelebration('🏆');
          }
        });
      }
    }

    // Find the new position based on completion status
    final newIndex = _findNewTaskPosition(column.tasks, task);

    // If the task doesn't need to move, just update the UI
    if (index == newIndex) {
      setState(() {});
      _saveCurrentTasks(); // Persist task changes even when position doesn't change
      return;
    }

    // Remove the task from current position with animation
    setState(() {
      column.tasks.removeAt(index);
    });

    column.listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTaskMoveAnimation(animation, task, columnId, index),
      duration: const Duration(milliseconds: 400),
    );

    // Insert the task at new position with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          final insertIndex = _findNewTaskPosition(column.tasks, task);
          column.tasks.insert(insertIndex, task);
          column.listKey.currentState?.insertItem(
            insertIndex,
            duration: const Duration(milliseconds: 400),
          );
        });
        _saveCurrentTasks(); // Persist task changes
      }
    });
  }

  int _findNewTaskPosition(List<Task> tasks, Task targetTask) {
    if (targetTask.isDone) {
      // For completed tasks, find the position after all incomplete tasks
      final firstCompletedIndex = tasks.indexWhere((t) => t.isDone);
      return firstCompletedIndex == -1 ? tasks.length : tasks.length;
    } else {
      // For incomplete tasks, find the position before all completed tasks
      final firstCompletedIndex = tasks.indexWhere((t) => t.isDone);
      return firstCompletedIndex == -1 ? tasks.length : firstCompletedIndex;
    }
  }

  Widget _buildTaskMoveAnimation(Animation<double> animation, Task task, String columnId, int index) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: Offset.zero,
          end: task.isDone
              ? const Offset(0.0, 1.5)  // Slide down when completing
              : const Offset(0.0, -1.5), // Slide up when uncompleting
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: ScaleTransition(
        scale: animation.drive(
          Tween<double>(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          ),
          child: EnhancedTaskCard(
            task: task,
            columnId: columnId,
            index: index,
            isChildMode: _isChildMode,
            animationType: routineAnimations[_currentRoutine]?.type ?? RoutineAnimation.slide,
            onToggle: () => _toggleTask(columnId, index),
          ),
        ),
      ),
    );
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
            child: EnhancedTaskCard(
              task: task,
              columnId: columnId,
              index: index,
              isChildMode: _isChildMode,
              animationType: routineAnimations[_currentRoutine]?.type ?? RoutineAnimation.slide,
              onToggle: () => _toggleTask(columnId, index),
            ),
          ),
        ),
      );
    });
    _saveCurrentTasks(); // Persist task changes
  }

  // Routine management methods
  // When user selects a routine from the drawer, it's a complete fresh start
  // Load the original routine template, all tasks not done
  void _loadRoutine(String name) async {
    setState(() {
      _currentRoutine = name;
      _isLoadingRoutine = true;
    });

    // Automatically switch theme based on routine
    if (name == 'Evening Routine') {
      widget.onDarkModeChange(true);  // Dark mode for evening
    } else if (name == 'Morning Routine') {
      widget.onDarkModeChange(false); // Light mode for morning
    }
    // Custom routines don't change the theme automatically

    // Clear existing tasks
    for (var column in columns) {
      column.tasks.clear();
    }

    // Load from routine template (fresh start with original order)
    if (routines[name] != null) {
      for (var column in columns) {
        for (int i = 0; i < routines[name]!.length; i++) {
          final task = routines[name]![i];
          Future.delayed(Duration(milliseconds: 300 + (i * 150)), () {
            if (mounted) {
              setState(() {
                column.tasks.add(Task(text: task.text, isDone: false, icon: task.icon));
              });
            }
          });
        }
      }
    }

    // Stop loading state and save the fresh state
    Future.delayed(Duration(milliseconds: 300 + ((routines[name]?.length ?? 0) * 150) + 200), () {
      if (mounted) {
        setState(() {
          _isLoadingRoutine = false;
        });
        _saveCurrentTasks(); // Save the fresh start state
      }
    });

    // Save current routine name
    await PreferencesService.saveCurrentRoutine(name);
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
            _saveRoutineData(); // Persist the new routine
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
                
                // Reload the tasks into columns to reflect the changes
                for (var column in columns) {
                  column.tasks.clear();
                  for (var task in tasks) {
                    column.tasks.add(Task(text: task.text, isDone: false, icon: task.icon));
                  }
                }
              }
            });

            _saveRoutineData(); // Persist routine changes
            _saveCurrentTasks(); // Also save the updated tasks

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
    _saveRoutineData(); // Persist routine deletion
  }

  void _toggleDarkMode(bool isDark) {
    widget.onDarkModeChange(isDark);
  }

  void _toggleViewMode() {
    setState(() {
      _forceTabView = !_forceTabView;
    });
  }

  void _toggleChildMode() async {
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
                onSubmitted: (value) async {
                  if (int.tryParse(value) == random) {
                    Navigator.pop(context);

                    // Exit kiosk mode on Android
                    await KioskService.stopScreenPinning();
                    await KioskService.exitImmersiveMode();

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
      // Enter child mode
      setState(() {
        _isChildMode = true;
      });

      // Enter kiosk mode on Android
      if (KioskService.isAndroid) {
        await KioskService.enterImmersiveMode();
        await KioskService.startScreenPinning();

        // Show a brief message about screen pinning
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.childModeLocked ?? 'Child mode activated. Screen is locked.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Widget builders

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Wrap with PopScope to prevent back button when in child mode
    return PopScope(
      canPop: !_isChildMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isChildMode) {
          // Show a message that child mode is active
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.childModeActive ?? 'Child mode is active. Use the exit button to leave.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: FallingIconsOverlay(
        controller: _fallingIconsController,
        child: Scaffold(
        key: _scaffoldKey,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode ? [
                Colors.grey.shade900,
                Colors.black,
                Colors.grey.shade800,
              ] : [
                Colors.orange.shade50,
                Colors.white,
                Colors.pink.shade50,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Menu button with circular background
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: Colors.orange.shade600,
                          ),
                                                     onPressed: _isChildMode ? null : () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      // Action button - only child mode remains in header
                      _buildActionButton(
                        icon: _isChildMode ? Icons.child_care : Icons.child_care_outlined,
                        color: _isChildMode ? Colors.orange : Colors.purple,
                        onPressed: _toggleChildMode,
                        tooltip: _isChildMode ? l10n.exitChildMode : l10n.enterChildMode,
                      ),
                    ],
                  ),
                ),

                // Main content - responsive layout
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use tabs for narrow screens (mobile) or if forced, columns otherwise
                      final isMobile = constraints.maxWidth < 600;
                      final useTabView = isMobile || _forceTabView;

                      if (useTabView) {
                        return _buildMobileTabView();
                      } else {
                        return _buildDesktopColumnView();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
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
          // User preferences
          forceTabView: _forceTabView,
          onToggleViewMode: _toggleViewMode,
          currentLanguage: _currentLocale?.languageCode ?? 'en',
          onLanguageChanged: _changeLanguage,
          onManageHousehold: _openManageHouseholdScreen,
          onWatchTutorial: _openTutorial,
          isDarkMode: isDarkMode,
          onToggleDarkMode: () => _toggleDarkMode(!isDarkMode),
        ),
      ),
      ), // FallingIconsOverlay
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 20,
            color: color,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // Mobile view with tabs
  Widget _buildMobileTabView() {
    return RoutineTabView(
      tabController: _tabController,
      columns: columns,
      buildColumn: _buildEnhancedTaskColumn,
      buildAvatar: _buildAvatarWidget,
      getMemberName: _getMemberNameFromColumn,
    );
  }

  // Desktop view with columns
  Widget _buildDesktopColumnView() {
    return RoutineColumnView(
      columns: columns,
      buildColumn: _buildEnhancedTaskColumn,
    );
  }

  Widget _buildEnhancedTaskColumn(ColumnData column) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1.0 - value) * 50),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode ? [
                      column.color.withOpacity(0.2),
                      Colors.grey.shade800,
                      column.color.withOpacity(0.1),
                    ] : [
                      column.color.withOpacity(0.1),
                      Colors.white,
                      column.color.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Column header
                    RoutineColumnHeader(
                      column: column,
                      isDarkMode: isDarkMode,
                      isChildMode: _isChildMode,
                      memberIcons: _memberIcons,
                      memberImages: _memberImages,
                      memberImageBytes: _memberImageBytes,
                      onAvatarTap: () => _showIconPicker(column.id),
                      onColorTap: () => _showColorPicker(column.id),
                      onEditNameTap: () => _showEditMemberNameDialog(column.id),
                      onAddTaskTap: () => _addTask(column.id),
                    ),

                    // Tasks list
                    Expanded(
                      child: _isLoadingRoutine
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : column.tasks.isEmpty
                              ? _buildEmptyState()
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  child: ReorderableListView.builder(
                                    key: column.listKey,
                                    itemCount: column.tasks.length,
                                    buildDefaultDragHandles: false,
                                    onReorder: _isChildMode ? (oldIndex, newIndex) {} : (oldIndex, newIndex) {
                                      setState(() {
                                        if (oldIndex < newIndex) {
                                          newIndex -= 1;
                                        }
                                        final task = column.tasks.removeAt(oldIndex);
                                        column.tasks.insert(newIndex, task);
                                      });
                                      _saveCurrentTasks(); // Persist task order changes
                                    },
                                    itemBuilder: (context, index) {
                                      final task = column.tasks[index];
                                      return EnhancedTaskCard(
                                        key: ValueKey('${column.id}_$index'),
                                        task: task,
                                        columnId: column.id,
                                        index: index,
                                        isChildMode: _isChildMode,
                                        animationType: routineAnimations[_currentRoutine]?.type ?? RoutineAnimation.slide,
                                        onToggle: () => _toggleTask(column.id, index),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Get member name from column (remove the suffix)
  String _getMemberNameFromColumn(ColumnData column) {
    final l10n = AppLocalizations.of(context)!;
    // Remove the tasks suffix to get the member name
    return column.name.replaceAll(l10n.tasksSuffix, '').trim();
  }

  Widget _buildAvatarWidget(ColumnData column, bool isDarkMode) {
    return MemberAvatarWidget(
      column: column,
      isDarkMode: isDarkMode,
      memberIcons: _memberIcons,
      memberImages: _memberImages,
      memberImageBytes: _memberImageBytes,
      isChildMode: _isChildMode,
      onTap: () => _showIconPicker(column.id),
      showEditBadge: false, // We'll add the badge in the column header
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt,
              size: 30,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTasksYet,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addTasksToGetStarted,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}