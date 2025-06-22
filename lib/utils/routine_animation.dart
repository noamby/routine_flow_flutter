import 'package:flutter/material.dart';

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

String getAnimationDescription(RoutineAnimation type) {
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