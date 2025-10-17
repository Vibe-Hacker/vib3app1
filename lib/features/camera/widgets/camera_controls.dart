import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';

class CameraControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;
  
  const CameraControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? AppTheme.primaryColor).withOpacity(0.2)
                  : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? (activeColor ?? AppTheme.primaryColor)
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? (activeColor ?? AppTheme.primaryColor)
                  : Colors.white,
              size: 24,
            ),
          ).animate(
            target: isActive ? 1 : 0,
          ).scaleXY(
            begin: 1.0,
            end: 1.1,
            duration: 200.ms,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? (activeColor ?? AppTheme.primaryColor)
                  : Colors.white,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class RecordButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressEnd;
  final bool isRecording;
  
  const RecordButton({
    Key? key,
    required this.onTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.isRecording = false,
  }) : super(key: key);
  
  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onLongPress: widget.onLongPress,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) => widget.onLongPressEnd!()
          : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_animationController.value * 0.1),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4 + (_animationController.value * 2),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  widget.isRecording ? 8.0 : 4.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: widget.isRecording
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    color: widget.isRecording ? Colors.red : Colors.white,
                    borderRadius: widget.isRecording
                        ? BorderRadius.circular(8)
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CameraModeSwitcher extends StatelessWidget {
  final List<CameraMode> modes;
  final CameraMode selectedMode;
  final Function(CameraMode) onModeChanged;
  
  const CameraModeSwitcher({
    Key? key,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isSelected = mode == selectedMode;
          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  _getModeLabel(mode),
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _getModeLabel(CameraMode mode) {
    switch (mode) {
      case CameraMode.video:
        return 'Video';
      case CameraMode.photo:
        return 'Photo';
      case CameraMode.story:
        return 'Story';
      case CameraMode.live:
        return 'Live';
    }
  }
}

enum CameraMode { video, photo, story, live }