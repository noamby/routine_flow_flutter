import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../utils/routine_animation.dart';

class EnhancedTaskCard extends StatelessWidget {
  final Task task;
  final String columnId;
  final int index;
  final bool isChildMode;
  final RoutineAnimation animationType;
  final VoidCallback onToggle;

  const EnhancedTaskCard({
    super.key,
    required this.task,
    required this.columnId,
    required this.index,
    required this.isChildMode,
    required this.animationType,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
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
              onTap: onToggle,
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
                    if (!isChildMode && !task.isDone) ...[
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
}

