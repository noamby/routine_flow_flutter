import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

void main() {
  runApp(const RoutineFlowApp());
}

class RoutineFlowApp extends StatelessWidget {
  const RoutineFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class Task {
  String text;
  bool isDone;

  Task({required this.text, this.isDone = false});
}

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      widget.onToggle();
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedSlide(
            offset: Offset(0, _slideAnimation.value),
            duration: const Duration(milliseconds: 300),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Checkbox(
                  value: widget.task.isDone,
                  onChanged: (bool? value) => _handleTap(),
                ),
                title: Text(
                  widget.task.text,
                  style: TextStyle(
                    decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
                    color: widget.task.isDone ? Colors.grey : null,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(String) onAdd;

  const AddTaskDialog({super.key, required this.onAdd});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _textController = TextEditingController();
  bool _showEmojiPicker = false;

  final List<String> _quickEmojis = [
    // Morning Routine
    '🌅', // Wake up
    '🦷', // Brush teeth
    '👕', // Get dressed
    '🍳', // Breakfast
    '🥛', // Milk
    '🍎', // Apple
    '🍌', // Banana
    '🍞', // Bread
    '🎒', // School bag
    '🚌', // School bus
    
    // School Activities
    '📚', // Books
    '✏️', // Pencil
    '🎨', // Art
    '🎵', // Music
    '⚽', // Sports
    '🎮', // Games
    '🎲', // Board games
    '🎪', // Fun activities
    '🎯', // Target/Goals
    '🏆', // Achievement
    
    // After School & Evening
    '🍪', // Snack
    '🍦', // Ice cream
    '🛁', // Bath
    '🦖', // Toys/Dinosaurs
    '🐶', // Pets
    '🌙', // Night time
    '⭐', // Stars
    '🌠', // Shooting star
    '🌜', // Moon
    '😴', // Sleep
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    // If the text field is empty or no selection, append the emoji at the end
    if (text.isEmpty || selection.start < 0) {
      _textController.text = text + emoji;
      _textController.selection = TextSelection.collapsed(offset: text.length + emoji.length);
      return;
    }

    // Otherwise, insert at the current cursor position
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickEmojis.map((emoji) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => _insertEmoji(emoji),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter task text',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                  },
                ),
              ),
              maxLines: 3,
            ),
            if (_showEmojiPicker) Container(
              height: 250,
              margin: const EdgeInsets.only(top: 8),
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _insertEmoji(emoji.emoji);
                  setState(() {
                    _showEmojiPicker = false;
                  });
                },
                config: Config(
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  initCategory: Category.RECENT,
                  bgColor: Theme.of(context).scaffoldBackgroundColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  iconColorSelected: Theme.of(context).primaryColor,
                  iconColor: Colors.grey,
                  backspaceColor: Theme.of(context).primaryColor,
                  noRecents: const Text(
                    'No Recent Emojis',
                    style: TextStyle(fontSize: 20),
                  ),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  categoryIcons: const CategoryIcons(),
                  buttonMode: ButtonMode.MATERIAL,
                  checkPlatformCompatibility: true,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_textController.text.isNotEmpty) {
              widget.onAdd(_textController.text);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class ColumnData {
  final String id;
  String name;
  Color color;
  final List<Task> tasks;
  final GlobalKey<AnimatedListState> listKey;

  ColumnData({
    required this.id,
    required this.name,
    required this.color,
    required this.tasks,
    required this.listKey,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum RoutineAnimation {
  slide,
  fade,
  scale,
  bounce,
  rotate
}

class RoutineAnimationSettings {
  final Duration duration;
  final Curve curve;
  final RoutineAnimation type;

  RoutineAnimationSettings({
    required this.duration,
    required this.curve,
    required this.type,
  });
}

class _HomeScreenState extends State<HomeScreen> {
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

  String _getAnimationDescription(RoutineAnimation type) {
    switch (type) {
      case RoutineAnimation.slide:
        return 'Tasks slide in from the right';
      case RoutineAnimation.fade:
        return 'Tasks fade in smoothly';
      case RoutineAnimation.scale:
        return 'Tasks scale up from nothing';
      case RoutineAnimation.bounce:
        return 'Tasks bounce in from the bottom';
      case RoutineAnimation.rotate:
        return 'Tasks rotate in';
    }
  }

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

  void _removeColumn(String columnId) {
    setState(() {
      final index = columns.indexWhere((col) => col.id == columnId);
      if (index != -1) {
        columns.removeAt(index);
      }
    });
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
      column.tasks[index].isDone = !column.tasks[index].isDone;
      final task = column.tasks.removeAt(index);
      
      if (task.isDone) {
        column.tasks.add(task);
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
                onToggle: () => _toggleTask(columnId, column.tasks.length - 1),
              ),
            ),
          ),
        );
        column.listKey.currentState?.insertItem(column.tasks.length - 1);
      } else {
        final firstMarkedIndex = column.tasks.indexWhere((t) => t.isDone);
        final insertIndex = firstMarkedIndex == -1 ? column.tasks.length : firstMarkedIndex;
        column.tasks.insert(insertIndex, task);
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
      }
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
              subtitle: Text(_getAnimationDescription(type)),
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

    return StatefulBuilder(
      builder: (context, setState) {
        final animationController = AnimationController(
          duration: animation.duration,
          vsync: Scaffold.of(context),
        );

        final curvedAnimation = CurvedAnimation(
          parent: animationController,
          curve: animation.curve,
        );

        animationController.forward();

        switch (animation.type) {
          case RoutineAnimation.slide:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: TaskCard(
                task: task,
                onToggle: () => _toggleTask(columnId, index),
              ),
            );
          case RoutineAnimation.fade:
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: TaskCard(
                task: task,
                onToggle: () => _toggleTask(columnId, index),
              ),
            );
          case RoutineAnimation.scale:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: TaskCard(
                task: task,
                onToggle: () => _toggleTask(columnId, index),
              ),
            );
          case RoutineAnimation.bounce:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animationController,
                curve: Curves.bounceOut,
              )),
              child: TaskCard(
                task: task,
                onToggle: () => _toggleTask(columnId, index),
              ),
            );
          case RoutineAnimation.rotate:
            return RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: TaskCard(
                task: task,
                onToggle: () => _toggleTask(columnId, index),
              ),
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Routine Flow'),
          actions: [
            if (!_isChildMode) IconButton(
              icon: const Icon(Icons.view_column),
              onPressed: _showManageColumnsDialog,
              tooltip: 'Manage Columns',
            ),
            IconButton(
              icon: Icon(
                _isChildMode ? Icons.child_care : Icons.child_care_outlined,
                color: _isChildMode ? Colors.orange : null,
              ),
              onPressed: _toggleChildMode,
              tooltip: _isChildMode ? 'Exit Child Mode' : 'Enter Child Mode',
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
                child: const Center(
                  child: Text(
                    'Routines',
                    style: TextStyle(
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
                        leading: Icon(
                          routineIcons[name] ?? Icons.schedule,
                          color: name == 'Morning Routine' ? Colors.orange : 
                                 name == 'Evening Routine' ? Colors.indigo : 
                                 Theme.of(context).primaryColor,
                        ),
                        title: Text(name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.animation),
                              onPressed: () => _showAnimationPicker(name),
                              tooltip: 'Change Animation',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditRoutineScreen(
                                      name: name,
                                      tasks: routines[name]!,
                                      icon: routineIcons[name] ?? Icons.schedule,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    routines[name] = result['tasks'];
                                    routineIcons[name] = result['icon'];
                                  });
                                }
                              },
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
                      title: const Text('Add New Routine'),
                      onTap: () {
                        Navigator.pop(context);
                        _addNewRoutine();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Tasks', style: TextStyle(color: Colors.red)),
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
                            ) : GestureDetector(
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
                          Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.color_lens_outlined),
                                onPressed: () => _showColorPicker(column.id),
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addTask(column.id),
                                padding: const EdgeInsets.all(8),
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

class AddRoutineScreen extends StatefulWidget {
  final Function(String, List<Task>, IconData, RoutineAnimationSettings) onAdd;

  const AddRoutineScreen({super.key, required this.onAdd});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  final _nameController = TextEditingController();
  final List<Task> _tasks = [];
  final _listKey = GlobalKey<AnimatedListState>();
  IconData _selectedIcon = Icons.schedule;
  RoutineAnimationSettings _animationSettings = RoutineAnimationSettings(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    type: RoutineAnimation.slide,
  );

  final List<IconData> _availableIcons = [
    Icons.schedule,
    Icons.wb_sunny,
    Icons.nightlight,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.book,
    Icons.shopping_cart,
    Icons.cleaning_services,
    Icons.fitness_center,
    Icons.pets,
    Icons.games,
    Icons.school,
    Icons.work,
    Icons.restaurant,
    Icons.bedtime,
  ];

  String _getAnimationDescription(RoutineAnimation type) {
    switch (type) {
      case RoutineAnimation.slide:
        return 'Tasks slide in from the right';
      case RoutineAnimation.fade:
        return 'Tasks fade in smoothly';
      case RoutineAnimation.scale:
        return 'Tasks scale up from nothing';
      case RoutineAnimation.bounce:
        return 'Tasks bounce in from the bottom';
      case RoutineAnimation.rotate:
        return 'Tasks rotate in';
    }
  }

  void _showAnimationPicker() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Animation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoutineAnimation.values.map((type) {
            return ListTile(
              leading: Radio<RoutineAnimation>(
                value: type,
                groupValue: _animationSettings.type,
                onChanged: (value) {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _animationSettings = RoutineAnimationSettings(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      type: value!,
                    );
                  });
                },
              ),
              title: Text(type.name.toUpperCase()),
              subtitle: Text(_getAnimationDescription(type)),
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

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon ? Theme.of(context).primaryColor : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onAdd: (text) {
          setState(() {
            _tasks.add(Task(text: text));
            _listKey.currentState?.insertItem(_tasks.length - 1);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeTask(int index) {
    setState(() {
      final task = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
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
              onToggle: () {},
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Routine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showIconPicker,
                  icon: Icon(_selectedIcon),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showAnimationPicker,
                  icon: const Icon(Icons.animation),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              key: _listKey,
              padding: const EdgeInsets.all(8),
              itemCount: _tasks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final task = _tasks.removeAt(oldIndex);
                  _tasks.insert(newIndex, task);
                });
              },
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey(_tasks[index]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _removeTask(index),
                  child: TaskCard(
                    task: _tasks[index],
                    onToggle: () {},
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _tasks.isNotEmpty) {
                      widget.onAdd(_nameController.text, _tasks, _selectedIcon, _animationSettings);
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Routine'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditRoutineScreen extends StatefulWidget {
  final String name;
  final List<Task> tasks;
  final IconData icon;

  const EditRoutineScreen({
    super.key,
    required this.name,
    required this.tasks,
    required this.icon,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _nameController = TextEditingController();
  final List<Task> _tasks = [];
  final _listKey = GlobalKey<AnimatedListState>();
  late IconData _selectedIcon;

  final List<IconData> _availableIcons = [
    Icons.schedule,
    Icons.wb_sunny,
    Icons.nightlight,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.book,
    Icons.shopping_cart,
    Icons.cleaning_services,
    Icons.fitness_center,
    Icons.pets,
    Icons.games,
    Icons.school,
    Icons.work,
    Icons.restaurant,
    Icons.bedtime,
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _tasks.addAll(widget.tasks.map((task) => Task(text: task.text)));
    _selectedIcon = widget.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onAdd: (text) {
          setState(() {
            _tasks.add(Task(text: text));
            _listKey.currentState?.insertItem(_tasks.length - 1);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeTask(int index) {
    setState(() {
      final task = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
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
              onToggle: () {},
            ),
          ),
        ),
      );
    });
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon ? Theme.of(context).primaryColor : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showIconPicker,
                  icon: Icon(_selectedIcon),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              key: _listKey,
              padding: const EdgeInsets.all(8),
              itemCount: _tasks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final task = _tasks.removeAt(oldIndex);
                  _tasks.insert(newIndex, task);
                });
              },
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey(_tasks[index]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _removeTask(index),
                  child: TaskCard(
                    task: _tasks[index],
                    onToggle: () {},
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _tasks.isNotEmpty) {
                      Navigator.pop(context, {
                        'name': _nameController.text,
                        'tasks': _tasks,
                        'icon': _selectedIcon,
                      });
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
