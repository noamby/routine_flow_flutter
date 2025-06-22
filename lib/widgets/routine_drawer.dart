import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/task.dart';
import '../utils/routine_animation.dart';

class RoutineDrawer extends StatelessWidget {
  final Map<String, List<Task>> routines;
  final Map<String, IconData> routineIcons;
  final Function(String) onRoutineSelected;
  final Function(String) onAnimationPicker;
  final Function(String) onDeleteRoutine;
  final VoidCallback onAddNewRoutine;
  final VoidCallback onClearAllTasks;
  final Function(String) getLocalizedRoutineName;

  const RoutineDrawer({
    super.key,
    required this.routines,
    required this.routineIcons,
    required this.onRoutineSelected,
    required this.onAnimationPicker,
    required this.onDeleteRoutine,
    required this.onAddNewRoutine,
    required this.onClearAllTasks,
    required this.getLocalizedRoutineName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
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
                        Expanded(child: Text(getLocalizedRoutineName(name))),
                        IconButton(
                          icon: const Icon(Icons.animation, size: 20),
                          onPressed: () => onAnimationPicker(name),
                        ),
                        if (isCustomRoutine)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => onDeleteRoutine(name),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onRoutineSelected(name);
                    },
                  );
                }).toList(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.addNewRoutine),
                  onTap: () {
                    Navigator.pop(context);
                    onAddNewRoutine();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(l10n.clearAllTasks, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onClearAllTasks();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 