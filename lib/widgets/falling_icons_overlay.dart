import 'dart:math';
import 'package:flutter/material.dart';

/// Types of celebration animations
enum CelebrationAnimationType { falling, zoom }

/// Controller for triggering celebration animations from anywhere in the app
class FallingIconsController extends ChangeNotifier {
  String? _currentIcon;
  int _triggerCount = 0;
  CelebrationAnimationType _animationType = CelebrationAnimationType.falling;

  String? get currentIcon => _currentIcon;
  int get triggerCount => _triggerCount;
  CelebrationAnimationType get animationType => _animationType;

  /// Triggers the falling animation with the specified emoji/icon
  void triggerAnimation(String icon) {
    _currentIcon = icon;
    _animationType = CelebrationAnimationType.falling;
    _triggerCount++;
    notifyListeners();
  }

  /// Triggers a zoom celebration (single emoji that grows and shrinks)
  void triggerZoomCelebration(String icon) {
    _currentIcon = icon;
    _animationType = CelebrationAnimationType.zoom;
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
  
  // Zoom celebration state
  AnimationController? _zoomController;
  String? _zoomIcon;

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
    _zoomController?.dispose();
    super.dispose();
  }

  void _onAnimationTriggered() {
    // Only trigger if this is a new animation request
    if (widget.controller.triggerCount != _lastTriggerCount) {
      _lastTriggerCount = widget.controller.triggerCount;
      final icon = widget.controller.currentIcon;
      if (icon != null) {
        if (widget.controller.animationType == CelebrationAnimationType.zoom) {
          _triggerZoomCelebration(icon);
        } else {
          _spawnFallingIcons(icon);
        }
      }
    }
  }

  void _triggerZoomCelebration(String icon) {
    // Dispose previous controller if exists
    _zoomController?.dispose();
    
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    setState(() {
      _zoomIcon = icon;
    });

    _zoomController!.forward().then((_) {
      if (mounted) {
        _zoomController?.dispose();
        _zoomController = null;
        setState(() {
          _zoomIcon = null;
        });
      }
    });
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
        // Zoom celebration overlay
        if (_zoomIcon != null && _zoomController != null)
          _buildZoomCelebration(),
      ],
    );
  }

  Widget _buildZoomCelebration() {
    return AnimatedBuilder(
      animation: _zoomController!,
      builder: (context, child) {
        final progress = _zoomController!.value;
        
        // Scale animation: grows from 0 to max size, holds, then shrinks back
        double scale;
        double opacity;
        
        if (progress < 0.2) {
          // Grow phase (0 to 0.2) - fast growth with bounce
          scale = Curves.elasticOut.transform(progress / 0.2);
          opacity = (progress / 0.2).clamp(0.0, 1.0);
        } else if (progress < 0.8) {
          // Hold phase (0.2 to 0.8) - stay at full size with gentle pulse
          final holdProgress = (progress - 0.2) / 0.6;
          scale = 1.0 + 0.08 * sin(holdProgress * pi * 3);
          opacity = 1.0;
        } else {
          // Shrink phase (0.8 to 1.0) - shrink and fade
          final shrinkProgress = (progress - 0.8) / 0.2;
          scale = 1.0 - Curves.easeIn.transform(shrinkProgress);
          opacity = 1.0 - shrinkProgress;
        }

        // Max font size relative to screen
        final screenSize = MediaQuery.of(context).size;
        final maxSize = screenSize.width * 0.5; // 50% of screen width
        final fontSize = maxSize * scale;

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1 * opacity),
              child: Center(
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Text(
                    _zoomIcon!,
                    style: TextStyle(
                      fontSize: fontSize.clamp(0.0, maxSize),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
