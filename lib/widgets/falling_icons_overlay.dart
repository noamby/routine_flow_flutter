import 'dart:math';
import 'package:flutter/material.dart';

/// Controller for triggering falling icon animations from anywhere in the app
class FallingIconsController extends ChangeNotifier {
  String? _currentIcon;
  int _triggerCount = 0;

  String? get currentIcon => _currentIcon;
  int get triggerCount => _triggerCount;

  /// Triggers the falling animation with the specified emoji/icon
  void triggerAnimation(String icon) {
    _currentIcon = icon;
    _triggerCount++;
    notifyListeners();
  }
}

/// Overlay widget that displays falling icons across the entire screen
/// Similar to Instagram's story reaction animation
class FallingIconsOverlay extends StatefulWidget {
  final FallingIconsController controller;
  final Widget child;
  final int iconCount;
  final Duration animationDuration;

  const FallingIconsOverlay({
    super.key,
    required this.controller,
    required this.child,
    this.iconCount = 20,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<FallingIconsOverlay> createState() => _FallingIconsOverlayState();
}

class _FallingIconsOverlayState extends State<FallingIconsOverlay>
    with TickerProviderStateMixin {
  final List<_FallingIconData> _fallingIcons = [];
  final Random _random = Random();
  int _lastTriggerCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onAnimationTriggered);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAnimationTriggered);
    for (final data in _fallingIcons) {
      data.controller.dispose();
    }
    super.dispose();
  }

  void _onAnimationTriggered() {
    // Only trigger if this is a new animation request
    if (widget.controller.triggerCount != _lastTriggerCount) {
      _lastTriggerCount = widget.controller.triggerCount;
      final icon = widget.controller.currentIcon;
      if (icon != null) {
        _spawnFallingIcons(icon);
      }
    }
  }

  void _spawnFallingIcons(String icon) {
    for (int i = 0; i < widget.iconCount; i++) {
      // Stagger the spawn times
      Future.delayed(Duration(milliseconds: _random.nextInt(400)), () {
        if (!mounted) return;

        final controller = AnimationController(
          duration: widget.animationDuration + Duration(milliseconds: _random.nextInt(1000)),
          vsync: this,
        );

        final data = _FallingIconData(
          icon: icon,
          controller: controller,
          startX: _random.nextDouble(),
          drift: (_random.nextDouble() - 0.5) * 0.2,
          size: 32.0 + _random.nextDouble() * 28.0,
          rotation: (_random.nextDouble() - 0.5) * 4.0,
        );

        setState(() {
          _fallingIcons.add(data);
        });

        controller.forward().then((_) {
          if (mounted) {
            controller.dispose();
            setState(() {
              _fallingIcons.remove(data);
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Falling icons overlay
        ..._fallingIcons.map((data) => _buildFallingIcon(data)),
      ],
    );
  }

  Widget _buildFallingIcon(_FallingIconData data) {
    return AnimatedBuilder(
      animation: data.controller,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final progress = data.controller.value;
        
        // Vertical position: from above screen to below
        final y = -data.size + (screenSize.height + data.size) * progress;
        
        // Horizontal position with drift
        final x = (data.startX + data.drift * progress) * screenSize.width;
        
        // Rotation increases over time
        final angle = data.rotation * progress * pi;
        
        // Fade out in last 20%
        final opacity = progress > 0.8 ? (1.0 - progress) / 0.2 : 1.0;

        return Positioned(
          left: x.clamp(0, screenSize.width - data.size),
          top: y,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: angle,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  data.icon,
                  style: TextStyle(
                    fontSize: data.size,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallingIconData {
  final String icon;
  final AnimationController controller;
  final double startX;
  final double drift;
  final double size;
  final double rotation;

  _FallingIconData({
    required this.icon,
    required this.controller,
    required this.startX,
    required this.drift,
    required this.size,
    required this.rotation,
  });
}
