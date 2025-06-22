import 'package:flutter/material.dart';

class LightSwitchWidget extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggle;
  final double size;

  const LightSwitchWidget({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
    this.size = 24.0,
  });

  @override
  State<LightSwitchWidget> createState() => _LightSwitchWidgetState();
}

class _LightSwitchWidgetState extends State<LightSwitchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isDarkMode) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LightSwitchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      if (widget.isDarkMode) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onToggle(!widget.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Icon(
            widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: widget.size,
            color: widget.isDarkMode 
              ? Colors.orange[300]
              : Colors.amber[600],
          );
        },
      ),
    );
  }
} 