import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/task.dart';
import '../models/column_data.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';
import '../utils/routine_animation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'add_routine_screen.dart';

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

  // Method to easily update the column names - call this to change the default columns
  void updateColumnNames(List<String> newNames) {
    setState(() {
      _columnNames = newNames;
      _initializeColumns();
    });
  }

  String _currentRoutine = 'Morning Routine';

  late Map<String, List<Task>> routines;
  final Map<String, IconData> routineIcons = {
    'Morning Routine': Icons.wb_sunny,
    'Evening Routine': Icons.nightlight,
  };

  final Map<String, RoutineAnimationSettings> routineAnimations = {
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

  bool _isDarkMode = false;
  bool _isChildMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeColumns();
    _initializeRoutines();
  }

  void _initializeColumns() {
    final l10n = AppLocalizations.of(context)!;
    final colors = [
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.pink.shade100,
      Colors.teal.shade100,
      Colors.amber.shade100,
      Colors.indigo.shade100,
    ];

    columns = _columnNames.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      return ColumnData(
        id: name.toLowerCase(),
        name: name + l10n.tasksSuffix,
        color: colors[index % colors.length],
        tasks: [],
        listKey: GlobalKey<AnimatedListState>(),
      );
    }).toList();
  }

  void _initializeRoutines() {
    final l10n = AppLocalizations.of(context)!;
    routines = {
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

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.english),
              leading: const Icon(Icons.language),
              onTap: () {
                widget.onLocaleChange(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.hebrew),
              leading: const Icon(Icons.language),
              onTap: () {
                widget.onLocaleChange(const Locale('he'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _addNewColumn() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addNewColumn),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterChildName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final newId = controller.text.toLowerCase();
                  final colors = [
                    Colors.green.shade100,
                    Colors.purple.shade100,
                    Colors.blue.shade100,
                    Colors.orange.shade100,
                    Colors.pink.shade100,
                    Colors.teal.shade100,
                    Colors.amber.shade100,
                    Colors.indigo.shade100,
                  ];
                  columns.add(ColumnData(
                    id: newId,
                    name: controller.text + l10n.tasksSuffix,
                    color: colors[columns.length % colors.length],
                    tasks: [],
                    listKey: GlobalKey<AnimatedListState>(),
                  ));
                  _columnNames.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

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
            child: TaskCard(
              task: task,
              onToggle: () => _toggleTask(columnId, insertIndex),
            ),
          ),
        ),
      );
      column.listKey.currentState?.insertItem(insertIndex);
    });
  }

  void _removeTask(String columnId, int index) {
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
            child: TaskCard(
              task: task,
              onToggle: () => _toggleTask(columnId, index),
            ),
          ),
        ),
      );
    });
  }

  void _showColorPicker(String columnId) {
    final l10n = AppLocalizations.of(context)!;
    final column = columns.firstWhere((col) => col.id == columnId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pickColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: column.color,
            onColorChanged: (color) {
              setState(() {
                column.color = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showEditColumnNameDialog(String columnId) {
    final l10n = AppLocalizations.of(context)!;
    final column = columns.firstWhere((col) => col.id == columnId);
    final controller = TextEditingController(text: column.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterColumnName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  column.name = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _loadRoutine(String name) {
    // Update theme based on routine
    setState(() {
      _isDarkMode = name == 'Evening Routine';
      _currentRoutine = name;
    });

    // First, remove all existing tasks with animation
    for (var column in columns) {
      Future.forEach(
        List.generate(column.tasks.length, (i) => i),
        (i) async {
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) {
            setState(() {
              if (column.tasks.isNotEmpty) {
                final task = column.tasks.removeLast();
                column.listKey.currentState?.removeItem(
                  column.tasks.length,
                  (context, animation) => SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: TaskCard(
                        task: task,
                        onToggle: () => _toggleTask(column.id, column.tasks.length),
                      ),
                    ),
                  ),
                );
              }
            });
          }
        },
      );
    }

    // After all tasks are removed, add new tasks with the selected animation
    Future.delayed(Duration(milliseconds: columns.first.tasks.length * 50 + 200), () {
      if (mounted) {
        for (var column in columns) {
          Future.forEach(
            routines[name]!,
            (task) async {
              await Future.delayed(const Duration(milliseconds: 50));
              if (mounted) {
                setState(() {
                  column.tasks.add(Task(text: task.text));
                  column.listKey.currentState?.insertItem(
                    column.tasks.length - 1,
                    duration: routineAnimations[name]?.duration ?? const Duration(milliseconds: 500),
                  );
                });
              }
            },
          );
        }
      }
    });
  }

  void _clearAllTasks() {
    for (var column in columns) {
      Future.forEach(
        List.generate(column.tasks.length, (i) => i),
        (i) async {
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) {
            setState(() {
              if (column.tasks.isNotEmpty) {
                final task = column.tasks.removeLast();
                column.listKey.currentState?.removeItem(
                  column.tasks.length,
                  (context, animation) => SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: TaskCard(
                        task: task,
                        onToggle: () => _toggleTask(column.id, column.tasks.length),
                      ),
                    ),
                  ),
                );
              }
            });
          }
        },
      );
    }
  }

  void _showManageColumnsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.manageColumns),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: columns.length,
            itemBuilder: (context, index) {
              final column = columns[index];
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: column.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(column.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (columns.length > 2)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _columnNames.removeAt(index);
                            columns.removeAt(index);
                          });
                          Navigator.pop(context);
                          _showManageColumnsDialog();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditColumnNameDialog(column.id);
                      },
                      tooltip: l10n.editNameTooltip,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addNewColumn();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addNewColumn),
          ),
        ],
      ),
    );
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

  void _deleteRoutine(String name) {
    setState(() {
      routines.remove(name);
      routineIcons.remove(name);
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

  void _showAnimationPicker(String routineName) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectAnimation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoutineAnimation.values.map((type) {
            final currentSettings = routineAnimations[routineName];
            String description;
            switch (type) {
              case RoutineAnimation.slide:
                description = l10n.tasksSlideInFromRight;
                break;
              case RoutineAnimation.fade:
                description = l10n.tasksFadeInSmoothly;
                break;
              case RoutineAnimation.scale:
                description = l10n.tasksScaleUpFromNothing;
                break;
              case RoutineAnimation.bounce:
                description = l10n.tasksBounceInFromBottom;
                break;
              case RoutineAnimation.rotate:
                description = l10n.tasksRotateIn;
                break;
            }
            return ListTile(
              leading: Radio<RoutineAnimation>(
                value: type,
                groupValue: currentSettings?.type,
                onChanged: (value) {
                  Navigator.pop(dialogContext);
                  setState(() {
                    routineAnimations[routineName] = RoutineAnimationSettings(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      type: value!,
                    );
                  });
                },
              ),
              title: Text(type.name.toUpperCase()),
              subtitle: Text(description),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTask(Task task, int index, String columnId, String routineName) {
    final animation = routineAnimations[routineName] ?? RoutineAnimationSettings(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      type: RoutineAnimation.slide,
    );

    return Card(
      key: ValueKey(task),
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
              if (!_isChildMode) ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedRoutineName(String routineName) {
    final l10n = AppLocalizations.of(context)!;
    switch (routineName) {
      case 'Morning Routine':
        return l10n.morningRoutine;
      case 'Evening Routine':
        return l10n.eveningRoutine;
      default:
        return routineName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
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
        drawer: _isChildMode ? null : Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    l10n.routines,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...routines.keys.map((name) {
                      final isCustomRoutine = !['Morning Routine', 'Evening Routine'].contains(name);
                      return ListTile(
                        leading: Icon(routineIcons[name] ?? Icons.schedule),
                        title: Row(
                          children: [
                            Expanded(child: Text(_getLocalizedRoutineName(name))),
                            IconButton(
                              icon: const Icon(Icons.animation, size: 20),
                              onPressed: () => _showAnimationPicker(name),
                            ),
                            if (isCustomRoutine)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteRoutine(name),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _loadRoutine(name);
                        },
                      );
                    }).toList(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(l10n.addNewRoutine),
                      onTap: () {
                        Navigator.pop(context);
                        _addNewRoutine();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(l10n.clearAllTasks, style: const TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        _clearAllTasks();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Row(
          children: columns.map((column) => Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: column.color.withOpacity(_isDarkMode ? 0.3 : 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _isChildMode ? Text(
                              column.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ) : Tooltip(
                              message: l10n.editNameTooltip,
                              child: GestureDetector(
                                onTap: () => _showEditColumnNameDialog(column.id),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        column.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.color_lens_outlined),
                                onPressed: () => _showColorPicker(column.id),
                                padding: const EdgeInsets.all(8),
                                tooltip: l10n.editColorTooltip,
                              ),
                              if (!_isChildMode) IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addTask(column.id),
                                padding: const EdgeInsets.all(8),
                                tooltip: l10n.addTaskTooltip,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    key: column.listKey,
                    padding: const EdgeInsets.all(8),
                    itemCount: column.tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      if (!_isChildMode) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final task = column.tasks.removeAt(oldIndex);
                          column.tasks.insert(newIndex, task);
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: ValueKey(column.tasks[index]),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: _isChildMode ? null : (direction) => _removeTask(column.id, index),
                        child: _buildAnimatedTask(column.tasks[index], index, column.id, _currentRoutine),
                      );
                    },
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
} 