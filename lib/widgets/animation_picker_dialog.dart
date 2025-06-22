import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/routine_animation.dart';

class AnimationPickerDialog extends StatelessWidget {
  final String routineName;
  final RoutineAnimationSettings? currentSettings;
  final Function(RoutineAnimation) onAnimationSelected;

  const AnimationPickerDialog({
    super.key,
    required this.routineName,
    required this.currentSettings,
    required this.onAnimationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
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
              groupValue: currentSettings?.type,
              onChanged: (value) {
                Navigator.pop(context);
                onAnimationSelected(value!);
                // Show a snackbar to confirm the change
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Animation changed to ${value.name.toUpperCase()}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            title: Text(
              type.name.toUpperCase(),
              style: TextStyle(
                fontWeight: currentSettings?.type == type ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(description),
            tileColor: currentSettings?.type == type ? Colors.blue.withOpacity(0.1) : null,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
} 