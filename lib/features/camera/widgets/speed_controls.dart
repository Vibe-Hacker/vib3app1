import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';
import '../screens/enhanced_camera_screen.dart';

class SpeedControlPanel extends StatelessWidget {
  final RecordingSpeed currentSpeed;
  final Function(RecordingSpeed) onSpeedChanged;
  
  const SpeedControlPanel({
    Key? key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 80,
      top: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption(
              speed: RecordingSpeed.slow,
              label: '0.3x',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 8),
            _buildSpeedOption(
              speed: RecordingSpeed.verySlow,
              label: '0.5x',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 8),
            _buildSpeedOption(
              speed: RecordingSpeed.normal,
              label: '1x',
              icon: Icons.videocam,
            ),
            const SizedBox(height: 8),
            _buildSpeedOption(
              speed: RecordingSpeed.fast,
              label: '2x',
              icon: Icons.directions_run,
            ),
            const SizedBox(height: 8),
            _buildSpeedOption(
              speed: RecordingSpeed.veryFast,
              label: '3x',
              icon: Icons.flash_on,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0),
    );
  }
  
  Widget _buildSpeedOption({
    required RecordingSpeed speed,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentSpeed == speed;
    
    return GestureDetector(
      onTap: () => onSpeedChanged(speed),
      child: Container(
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ).animate(
        target: isSelected ? 1 : 0,
      ).scaleXY(
        begin: 1.0,
        end: 1.1,
        duration: 200.ms,
      ),
    );
  }
}