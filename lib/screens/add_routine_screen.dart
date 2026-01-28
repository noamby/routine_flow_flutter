import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/add_task_dialog.dart';
import '../utils/routine_animation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  void _showAnimationPicker() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectAnimation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoutineAnimation.values.map((type) {
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

  void _showIconPicker() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectIcon),
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

  void _editTask(int index) {
    final currentTask = _tasks[index];
    
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialText: currentTask.text,
        onAdd: (text) {
          setState(() {
            _tasks[index] = Task(text: text, isDone: currentTask.isDone);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeTask(int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode 
                          ? Colors.orange.shade700 
                          : Colors.orange.shade100,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode 
                              ? Colors.white 
                              : Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.text,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
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
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
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
                    // Back button with circular background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDarkMode ? Colors.white : Colors.orange.shade600,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        l10n.addNewRoutine,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Input section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.routineName,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode 
                                      ? Colors.grey.shade800.withOpacity(0.3)
                                      : Colors.grey.shade50,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _showIconPicker,
                                  icon: Icon(
                                    _selectedIcon,
                                    color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600,
                                  ),
                                  tooltip: l10n.selectIcon,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.pink.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _showAnimationPicker,
                                  icon: Icon(
                                    Icons.animation,
                                    color: isDarkMode ? Colors.pink.shade300 : Colors.pink.shade600,
                                  ),
                                  tooltip: l10n.selectAnimation,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tasks section
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ReorderableListView.builder(
                              key: _listKey,
                              padding: const EdgeInsets.all(12),
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
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (direction) => _removeTask(index),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Task number indicator
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDarkMode 
                                                ? Colors.orange.shade700 
                                                : Colors.orange.shade100,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode 
                                                    ? Colors.white 
                                                    : Colors.orange.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _tasks[index].text,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _editTask(index),
                                            icon: Icon(
                                              Icons.edit, 
                                              size: 18,
                                              color: Colors.grey.shade400,
                                            ),
                                            tooltip: l10n.edit,
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(
                                              Icons.drag_handle,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addTask,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addTask),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.orange.shade100,
                                foregroundColor: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_nameController.text.isNotEmpty && _tasks.isNotEmpty) {
                                  widget.onAdd(_nameController.text, _tasks, _selectedIcon, _animationSettings);
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: Text(l10n.saveRoutine),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.pink.shade100,
                                foregroundColor: isDarkMode ? Colors.pink.shade300 : Colors.pink.shade700,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 