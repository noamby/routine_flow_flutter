import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../services/routine_service.dart';
import '../services/preferences_service.dart';
import 'add_routine_screen.dart';
import 'edit_routine_screen.dart';

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

  late List<ColumnData> columns;
  String _currentRoutine = 'Morning Routine';
  late Map<String, List<Task>> routines;
  late Map<String, IconData> routineIcons;
  late Map<String, RoutineAnimationSettings> routineAnimations;


  bool _isChildMode = false;
  bool _isLoadingRoutine = false;

  bool _isInitialized = false;
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    // Initialize member names from saved preferences or use defaults
    _memberNames = widget.initialMembers ?? ['Assaf', 'Ofir'];
    _loadMemberAvatars();
  }

  Future<void> _loadMemberAvatars() async {
    final prefs = await SharedPreferences.getInstance();
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

    // Load the default Morning Routine tasks - add ALL tasks to ALL columns
    if (routines[_currentRoutine] != null) {
      final tasks = routines[_currentRoutine]!;
      for (var column in columns) {
        for (var task in tasks) {
          column.tasks.add(Task(text: task.text));
        }
      }
    }
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
    });
  }

  // Dialog methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => LanguageDialog(onLocaleChange: widget.onLocaleChange),
    );
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
        },
      ),
    );
  }

  void _showIconPicker(String columnId) {
    final availableIcons = [
      Icons.person,
      Icons.face,
      Icons.child_care,
      Icons.boy,
      Icons.girl,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
      Icons.mood,
      Icons.emoji_emotions,
      Icons.pets,
      Icons.favorite,
      Icons.star,
      Icons.brightness_5,
      Icons.wb_sunny,
      Icons.sports_soccer,
      Icons.sports_basketball,
      Icons.sports_baseball,
      Icons.sports_football,
      Icons.music_note,
      Icons.palette,
      Icons.brush,
      Icons.draw,
      Icons.cake,
      Icons.toys,
      Icons.rocket_launch,
      Icons.beach_access,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Avatar Icon'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final icon = availableIcons[index];
              final column = columns.firstWhere((col) => col.id == columnId);
              final isSelected = _memberIcons[columnId] == icon ||
                                 (_memberIcons[columnId] == null && icon == Icons.person);

              return InkWell(
                onTap: () {
                  setState(() {
                    _memberIcons[columnId] = icon;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? column.color.withOpacity(0.3)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? column.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: column.color,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _pickAndCropImage(columnId);
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Upload Image'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage(String columnId) async {
    try {
      print('Starting image picker...');

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      print('Image picked: ${image?.path}');

      if (image == null) {
        print('No image selected');
        return;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();
      print('Image bytes loaded: ${bytes.length}');

      if (kIsWeb) {
        // For web: store bytes in memory and base64 in preferences
        setState(() {
          _memberImageBytes[columnId] = bytes;
          _memberImages[columnId] = base64Encode(bytes);
          _memberIcons.remove(columnId);
        });
      } else {
        // For mobile: save to file system
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${columnId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savePath = '${directory.path}/$fileName';
        await File(savePath).writeAsBytes(bytes);

        setState(() {
          _memberImages[columnId] = savePath;
          _memberIcons.remove(columnId);
        });
      }

      await _saveMemberAvatars();

      print('Avatar updated for column: $columnId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }


  void _showManageHouseholdDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageColumnsDialog(
        columns: columns,
        onDelete: (index) {
          setState(() {
            _memberNames.removeAt(index);
            columns.removeAt(index);
          });
          _showManageHouseholdDialog();
        },
        onEdit: _showEditMemberNameDialog,
        onAddNew: _showAddMemberDialog,
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
    final column = columns.firstWhere((col) => col.id == columnId);
    final task = column.tasks[index];

    // Toggle the task status
    task.isDone = !task.isDone;

    // Find the new position based on completion status
    final newIndex = _findNewTaskPosition(column.tasks, task);

    // If the task doesn't need to move, just update the UI
    if (index == newIndex) {
      setState(() {});
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
          child: _buildEnhancedTaskCard(task, columnId, index),
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
            child: _buildEnhancedTaskCard(task, columnId, index),
          ),
        ),
      );
    });
  }

  // Routine management methods
  void _loadRoutine(String name) {
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

    // Add routine tasks with animation - add ALL tasks to ALL columns
    if (routines[name] != null) {
      for (var column in columns) {
        for (int i = 0; i < routines[name]!.length; i++) {
          final task = routines[name]![i];
          Future.delayed(Duration(milliseconds: 300 + (i * 150)), () {
            if (mounted) {
              setState(() {
                column.tasks.add(Task(text: task.text));
              });
            }
          });
        }
      }
    }

    // Stop loading state
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoadingRoutine = false;
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

  void _toggleDarkMode(bool isDark) {
    widget.onDarkModeChange(isDark);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                      // Action buttons
                      _buildActionButton(
                        icon: Icons.language,
                        color: Colors.blue,
                        onPressed: _showLanguageDialog,
                        tooltip: l10n.language,
                      ),
                      const SizedBox(width: 8),
                      if (!_isChildMode) ...[
                        _buildActionButton(
                          icon: Icons.home,
                          color: Colors.green,
                          onPressed: _showManageHouseholdDialog,
                          tooltip: l10n.manageHousehold,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildActionButton(
                        icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.amber,
                        onPressed: () => _toggleDarkMode(!isDarkMode),
                        tooltip: isDarkMode ? l10n.lightMode : l10n.darkMode,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: _isChildMode ? Icons.child_care : Icons.child_care_outlined,
                        color: _isChildMode ? Colors.orange : Colors.purple,
                        onPressed: _toggleChildMode,
                        tooltip: _isChildMode ? l10n.exitChildMode : l10n.enterChildMode,
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: columns.map((column) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildEnhancedTaskColumn(column),
                        ),
                      )).toList(),
                    ),
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
        ),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? column.color.withOpacity(0.3)
                            : column.color.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar - clickable to change icon/image
                          if (!_isChildMode)
                            GestureDetector(
                              onTap: () => _showIconPicker(column.id),
                              child: Stack(
                                children: [
                                  _buildAvatarWidget(column, isDarkMode),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            _buildAvatarWidget(column, isDarkMode),
                          const SizedBox(width: 12),
                          // Column title
                          Expanded(
                            child: Text(
                              column.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          // Action buttons
                          if (!_isChildMode) ...[
                            _buildColumnActionButton(
                              icon: Icons.palette,
                              color: column.color,
                              onPressed: () => _showColorPicker(column.id),
                              tooltip: l10n.editColorTooltip,
                            ),
                            const SizedBox(width: 4),
                            _buildColumnActionButton(
                              icon: Icons.edit,
                              color: Colors.blue,
                              onPressed: () => _showEditMemberNameDialog(column.id),
                              tooltip: l10n.editNameTooltip,
                            ),
                            const SizedBox(width: 4),
                            _buildColumnActionButton(
                              icon: Icons.add,
                              color: Colors.green,
                              onPressed: () => _addTask(column.id),
                              tooltip: l10n.addTaskTooltip,
                            ),
                          ],
                        ],
                      ),
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
                                    },
                                    itemBuilder: (context, index) {
                                      final task = column.tasks[index];
                                      return _buildEnhancedTaskCard(task, column.id, index);
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

  Widget _buildAvatarWidget(ColumnData column, bool isDarkMode) {
    // Check if custom image exists
    if (kIsWeb && _memberImageBytes.containsKey(column.id)) {
      // For web: use bytes
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 20,
        backgroundImage: MemoryImage(_memberImageBytes[column.id]!),
      );
    } else if (!kIsWeb && _memberImages.containsKey(column.id)) {
      // For mobile: use file path
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 20,
        backgroundImage: FileImage(File(_memberImages[column.id]!)),
      );
    }

    // Otherwise show icon
    return CircleAvatar(
      backgroundColor: column.color.withOpacity(0.2),
      radius: 20,
      child: Icon(
        _memberIcons[column.id] ?? Icons.person,
        color: isDarkMode ? Colors.white : column.color,
        size: 24,
      ),
    );
  }

  Widget _buildColumnActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 16,
            color: color,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildEnhancedTaskCard(Task task, String columnId, int index) {
    final animationType = routineAnimations[_currentRoutine]?.type ?? RoutineAnimation.slide;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${columnId}_$index'),
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        Widget animatedChild = Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Card(
            elevation: task.isDone ? 1 : 3,
            color: isDarkMode
                ? (task.isDone ? Colors.grey.shade800 : Colors.grey.shade700)
                : (task.isDone ? Colors.grey.shade100 : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _toggleTask(columnId, index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Custom checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isDone ? Colors.green : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: task.isDone ? Colors.green : Colors.transparent,
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Task text
                    Expanded(
                      child: Text(
                        task.text,
                        style: TextStyle(
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone
                              ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)
                              : (isDarkMode ? Colors.white : Colors.grey.shade800),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Drag handle
                    if (!_isChildMode && !task.isDone) ...[
                      const SizedBox(width: 8),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.drag_handle,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade400,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        // Apply animation based on type
        switch (animationType) {
          case RoutineAnimation.slide:
            return Transform.translate(
              offset: Offset((1.0 - animationValue) * 200, 0),
              child: Opacity(opacity: animationValue, child: animatedChild),
            );
          case RoutineAnimation.fade:
            return Opacity(opacity: animationValue, child: animatedChild);
          case RoutineAnimation.scale:
            return Transform.scale(
              scale: 0.5 + (animationValue * 0.5),
              child: Opacity(opacity: animationValue, child: animatedChild),
            );
          case RoutineAnimation.bounce:
            final bounceValue = animationValue < 0.5
                ? 4 * animationValue * animationValue * animationValue
                : 1 - 4 * (1 - animationValue) * (1 - animationValue) * (1 - animationValue);
            return Transform.translate(
              offset: Offset(0, (1.0 - bounceValue) * 100),
              child: Opacity(opacity: animationValue, child: animatedChild),
            );
          case RoutineAnimation.rotate:
            return Transform.rotate(
              angle: (1.0 - animationValue) * 0.5,
              child: Opacity(opacity: animationValue, child: animatedChild),
            );
        }
      },
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