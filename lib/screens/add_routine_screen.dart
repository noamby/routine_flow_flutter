import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';
import '../utils/routine_animation.dart';

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