import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/task.dart';
import '../models/column_data.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';
import '../utils/routine_animation.dart';
import 'add_routine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<ColumnData> columns = [
    ColumnData(
      id: 'assaf',
      name: "Assaf's Tasks",
      color: Colors.green.shade100,
      tasks: [],
      listKey: GlobalKey<AnimatedListState>(),
    ),
    ColumnData(
      id: 'ofir',
      name: "Ofir's Tasks",
      color: Colors.purple.shade100,
      tasks: [],
      listKey: GlobalKey<AnimatedListState>(),
    ),
  ];

  String _currentRoutine = 'Morning Routine';

  final Map<String, List<Task>> routines = {
    'Morning Routine': [
      Task(text: '🌅 Wake up'),
      Task(text: '🦷 Brush teeth'),
      Task(text: '👕 Get dressed'),
      Task(text: '🍳 Eat breakfast'),
      Task(text: '🎒 Pack bag'),
    ],
    'Evening Routine': [
      Task(text: '🛁 Take a bath'),
      Task(text: '🦷 Brush teeth'),
      Task(text: '📚 Read a book'),
      Task(text: '😴 Go to sleep'),
    ],
  };

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

  void _addNewColumn() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Column'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter child name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final newId = 'child_${columns.length}';
                  columns.add(ColumnData(
                    id: newId,
                    name: "${controller.text}'s Tasks",
                    color: Colors.blue.shade100,
                    tasks: [],
                    listKey: GlobalKey<AnimatedListState>(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
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
    final column = columns.firstWhere((col) => col.id == columnId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showEditColumnNameDialog(String columnId) {
    final column = columns.firstWhere((col) => col.id == columnId);
    final controller = TextEditingController(text: column.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Column Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter column name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Save'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Columns'),
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
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addNewColumn();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Column'),
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
          title: const Text('Exit Child Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter the number ${numberWords[random]}'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number',
                ),
                onSubmitted: (value) {
                  if (int.tryParse(value) == random) {
                    Navigator.pop(context);
                    setState(() {
                      _isChildMode = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect number. Please try again.'),
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
              child: const Text('Cancel'),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Animation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoutineAnimation.values.map((type) {
            final currentSettings = routineAnimations[routineName];
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
              subtitle: Text(getAnimationDescription(type)),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen - Under Construction'),
      ),
    );
  }
} 