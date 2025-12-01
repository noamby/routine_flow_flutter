import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/routine_animation.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final RoutineAnimationSettings? animationSettings;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.animationSettings,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationSettings?.duration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start the animation only once when the widget is first created
    if (!_hasAnimated) {
      _controller.forward().then((_) {
        _hasAnimated = true;
      });
    }
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
        Widget taskWidget = Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.task.isDone,
                    onChanged: (bool? value) => _handleTap(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.task.text,
                      style: TextStyle(
                        decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
                        color: widget.task.isDone ? Colors.grey : null,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          ),
        );

        if (widget.animationSettings != null) {
          switch (widget.animationSettings!.type) {
            case RoutineAnimation.slide:
              taskWidget = SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: widget.animationSettings!.curve,
                )),
                child: taskWidget,
              );
              break;
            case RoutineAnimation.fade:
              taskWidget = FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                  parent: _controller,
                  curve: widget.animationSettings!.curve,
                )),
                child: taskWidget,
              );
              break;
            case RoutineAnimation.scale:
              taskWidget = ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                  parent: _controller,
                  curve: widget.animationSettings!.curve,
                )),
                child: taskWidget,
              );
              break;
            case RoutineAnimation.bounce:
              taskWidget = SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: Curves.bounceOut,
                )),
                child: taskWidget,
              );
              break;
            case RoutineAnimation.rotate:
              taskWidget = RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                  parent: _controller,
                  curve: widget.animationSettings!.curve,
                )),
                child: taskWidget,
              );
              break;
          }
        }

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedSlide(
            offset: Offset(0, _slideAnimation.value),
            duration: const Duration(milliseconds: 300),
            child: taskWidget,
          ),
        );
      },
    );
  }
}