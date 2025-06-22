import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/add_task_dialog.dart';
import '../utils/routine_animation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditRoutineScreen extends StatefulWidget {
  final String routineName;
  final String displayName;
  final List<Task> tasks;
  final IconData icon;
  final RoutineAnimationSettings animationSettings;
  final bool isDefaultRoutine;
  final Function(String, String, List<Task>, IconData, RoutineAnimationSettings) onSave;

  const EditRoutineScreen({
    super.key,
    required this.routineName,
    required this.displayName,
    required this.tasks,
    required this.icon,
    required this.animationSettings,
    required this.isDefaultRoutine,
    required this.onSave,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  late final TextEditingController _nameController;
  late List<Task> _tasks;
  final _listKey = GlobalKey<AnimatedListState>();
  late IconData _selectedIcon;
  late RoutineAnimationSettings _animationSettings;

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
    _nameController = TextEditingController(text: widget.displayName);
    _tasks = widget.tasks.map((task) => Task(text: task.text, isDone: task.isDone)).toList();
    _selectedIcon = widget.icon;
    _animationSettings = widget.animationSettings;
  }

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
    final controller = TextEditingController(text: currentTask.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.edit),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.enterTaskText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _tasks[index] = Task(text: controller.text, isDone: currentTask.isDone);
                });
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
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
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.isDone,
                      onChanged: null,
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editRoutine),
        actions: [
          IconButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _tasks.isNotEmpty) {
                widget.onSave(
                  widget.routineName, // original name
                  _nameController.text, // new name
                  _tasks,
                  _selectedIcon,
                  _animationSettings,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_nameController.text.isEmpty 
                      ? 'Please enter a routine name' 
                      : 'Please add at least one task'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            tooltip: l10n.saveChanges,
          ),
        ],
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
                    enabled: !widget.isDefaultRoutine,
                    decoration: InputDecoration(
                      labelText: l10n.routineName,
                      border: const OutlineInputBorder(),
                      helperText: widget.isDefaultRoutine 
                        ? l10n.defaultRoutineNameCannotBeChanged
                        : null,
                      helperMaxLines: 2,
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
                  tooltip: l10n.selectIcon,
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showAnimationPicker,
                  icon: const Icon(Icons.animation),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                  tooltip: l10n.selectAnimation,
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
                  key: ValueKey('${_tasks[index].text}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _removeTask(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _tasks[index].isDone,
                            onChanged: (bool? value) {
                              setState(() {
                                _tasks[index].isDone = !_tasks[index].isDone;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editTask(index),
                              child: Text(
                                _tasks[index].text,
                                style: TextStyle(
                                  decoration: _tasks[index].isDone ? TextDecoration.lineThrough : null,
                                  color: _tasks[index].isDone ? Colors.grey : null,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _editTask(index),
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: l10n.edit,
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    ),
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
                  label: Text(l10n.addTask),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _tasks.isNotEmpty) {
                      widget.onSave(
                        widget.routineName, // original name
                        _nameController.text, // new name
                        _tasks,
                        _selectedIcon,
                        _animationSettings,
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_nameController.text.isEmpty 
                            ? 'Please enter a routine name' 
                            : 'Please add at least one task'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: Text(l10n.saveChanges),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 