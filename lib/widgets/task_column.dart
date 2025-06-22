import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/column_data.dart';
import '../models/task.dart';

class TaskColumn extends StatelessWidget {
  final ColumnData column;
  final bool isDarkMode;
  final bool isChildMode;
  final bool isLoadingRoutine;
  final Function(String) onToggleTask;
  final Function(String) onRemoveTask;
  final Function(String) onEditColumnName;
  final Function(String) onShowColorPicker;
  final Function(String) onAddTask;
  final Function(int, int) onReorder;
  final Widget Function(Widget, int) buildAnimatedTaskWrapper;
  final Widget Function(Task, String, int) buildTaskCardWithDragHandle;

  const TaskColumn({
    super.key,
    required this.column,
    required this.isDarkMode,
    required this.isChildMode,
    required this.isLoadingRoutine,
    required this.onToggleTask,
    required this.onRemoveTask,
    required this.onEditColumnName,
    required this.onShowColorPicker,
    required this.onAddTask,
    required this.onReorder,
    required this.buildAnimatedTaskWrapper,
    required this.buildTaskCardWithDragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: column.color.withOpacity(isDarkMode ? 0.3 : 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: isChildMode ? Text(
                        column.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ) : Tooltip(
                        message: l10n.editNameTooltip,
                        child: GestureDetector(
                          onTap: () => onEditColumnName(column.id),
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
                          onPressed: () => onShowColorPicker(column.id),
                          padding: const EdgeInsets.all(8),
                          tooltip: l10n.editColorTooltip,
                        ),
                        if (!isChildMode) IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onAddTask(column.id),
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
              padding: const EdgeInsets.all(8),
              itemCount: column.tasks.length,
              onReorder: (oldIndex, newIndex) {
                if (!isChildMode) {
                  onReorder(oldIndex, newIndex);
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
                  onDismissed: isChildMode ? null : (direction) => onRemoveTask('${column.id}_$index'),
                  child: isLoadingRoutine 
                    ? buildAnimatedTaskWrapper(
                        buildTaskCardWithDragHandle(column.tasks[index], column.id, index),
                        index,
                      )
                    : buildTaskCardWithDragHandle(column.tasks[index], column.id, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 