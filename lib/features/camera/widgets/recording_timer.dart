import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';

class RecordingTimer extends StatelessWidget {
  final int seconds;
  final int maxSeconds;
  final int segmentCount;
  
  const RecordingTimer({
    Key? key,
    required this.seconds,
    required this.maxSeconds,
    required this.segmentCount,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final progress = seconds / maxSeconds;
    final timeString = _formatTime(seconds);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).scaleXY(
            begin: 1.0,
            end: 1.3,
            duration: 1.seconds,
          ).then().scaleXY(
            begin: 1.3,
            end: 1.0,
            duration: 1.seconds,
          ),
          
          const SizedBox(width: 8),
          
          // Timer
          Text(
            timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Progress bar
          Container(
            width: 100,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progress > 0.8 ? Colors.orange : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().scaleX(
                    begin: 0,
                    end: 1,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
                ),
              ],
            ),
          ),
          
          // Segment indicator
          if (segmentCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                '$segmentCount',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}