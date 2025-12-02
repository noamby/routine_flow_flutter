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
  final Function(String) onEditRoutine;
  final VoidCallback onAddNewRoutine;
  final VoidCallback onClearAllTasks;
  final Function(String) getLocalizedRoutineName;
  // New parameters for user preferences
  final bool forceTabView;
  final VoidCallback onToggleViewMode;
  final String currentLanguage;
  final Function(String) onLanguageChanged;
  final VoidCallback onManageHousehold;

  const RoutineDrawer({
    super.key,
    required this.routines,
    required this.routineIcons,
    required this.onRoutineSelected,
    required this.onAnimationPicker,
    required this.onDeleteRoutine,
    required this.onEditRoutine,
    required this.onAddNewRoutine,
    required this.onClearAllTasks,
    required this.getLocalizedRoutineName,
    required this.forceTabView,
    required this.onToggleViewMode,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.onManageHousehold,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode ? [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ] : [
                  Colors.orange.shade400,
                  Colors.pink.shade300,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.routines,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Routines section
                ...routines.keys.map((name) {
                  final isCustomRoutine = !['Morning Routine', 'Evening Routine'].contains(name);
                  return ListTile(
                    leading: Icon(routineIcons[name] ?? Icons.schedule),
                    title: Row(
                      children: [
                        Expanded(child: Text(getLocalizedRoutineName(name))),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEditRoutine(name),
                          tooltip: l10n.editRoutine,
                        ),
                        IconButton(
                          icon: const Icon(Icons.animation, size: 20),
                          onPressed: () => onAnimationPicker(name),
                          tooltip: l10n.selectAnimation,
                        ),
                        if (isCustomRoutine)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => onDeleteRoutine(name),
                            tooltip: l10n.delete,
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onRoutineSelected(name);
                    },
                  );
                }),
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

                // User Preferences Section
                const Divider(thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.userPreferences,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),

                // View Mode Toggle
                ListTile(
                  leading: Icon(forceTabView ? Icons.view_carousel : Icons.view_column),
                  title: Text(l10n.viewMode),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        forceTabView ? l10n.tabView : l10n.columnView,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: forceTabView,
                        onChanged: (_) => onToggleViewMode(),
                        activeColor: Colors.teal,
                      ),
                    ],
                  ),
                ),

                // Language Picker
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: currentLanguage,
                      underline: const SizedBox(),
                      isDense: true,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.english),
                        ),
                        DropdownMenuItem(
                          value: 'he',
                          child: Text(l10n.hebrew),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onLanguageChanged(value);
                        }
                      },
                    ),
                  ),
                ),

                // Manage Household
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(l10n.manageHousehold),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    onManageHousehold();
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
