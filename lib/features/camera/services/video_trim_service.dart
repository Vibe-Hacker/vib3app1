import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/multi_trim_slider.dart';

// Service to handle video trim information without actual processing
// This stores trim data that can be processed server-side or with future FFmpeg integration
class VideoTrimService {
  static final VideoTrimService _instance = VideoTrimService._internal();
  factory VideoTrimService() => _instance;
  VideoTrimService._internal();
  
  // Save trim data for later processing
  Future<String> saveTrimData({
    required String videoPath,
    required List<TrimSegment> segments,
    required Duration videoDuration,
  }) async {
    final trimData = {
      'videoPath': videoPath,
      'videoDuration': videoDuration.inMilliseconds,
      'segments': segments.map((s) => {
        'start': s.start,
        'end': s.end,
        'colorValue': s.color.value,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Generate unique ID for this trim job
    final trimId = 'trim_${DateTime.now().millisecondsSinceEpoch}';
    
    // Save to SharedPreferences for now
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(trimId, jsonEncode(trimData));
    
    return trimId;
  }
  
  // Get trim data by ID
  Future<Map<String, dynamic>?> getTrimData(String trimId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(trimId);
    if (dataString != null) {
      return jsonDecode(dataString);
    }
    return null;
  }
  
  // Get all pending trim jobs
  Future<List<String>> getPendingTrimJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys.where((key) => key.startsWith('trim_')).toList();
  }
  
  // Delete trim data
  Future<void> deleteTrimData(String trimId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(trimId);
  }
  
  // Calculate total duration of trimmed segments
  double calculateTotalDuration(List<TrimSegment> segments, Duration videoDuration) {
    double totalSeconds = 0;
    for (final segment in segments) {
      totalSeconds += (segment.end - segment.start) * videoDuration.inSeconds;
    }
    return totalSeconds;
  }
  
  // Validate segments (no overlaps)
  bool validateSegments(List<TrimSegment> segments) {
    for (int i = 0; i < segments.length; i++) {
      for (int j = i + 1; j < segments.length; j++) {
        final seg1 = segments[i];
        final seg2 = segments[j];
        
        // Check for overlap
        if ((seg1.start >= seg2.start && seg1.start <= seg2.end) ||
            (seg1.end >= seg2.start && seg1.end <= seg2.end) ||
            (seg1.start <= seg2.start && seg1.end >= seg2.end)) {
          return false;
        }
      }
    }
    return true;
  }
  
  // Generate preview timestamps for each segment
  List<Map<String, dynamic>> generatePreviewTimestamps(
    List<TrimSegment> segments,
    Duration videoDuration,
  ) {
    return segments.map((segment) {
      final startMs = (segment.start * videoDuration.inMilliseconds).toInt();
      final endMs = (segment.end * videoDuration.inMilliseconds).toInt();
      final durationMs = endMs - startMs;
      
      return {
        'startMs': startMs,
        'endMs': endMs,
        'durationMs': durationMs,
        'startTime': _formatMilliseconds(startMs),
        'endTime': _formatMilliseconds(endMs),
        'duration': _formatMilliseconds(durationMs),
      };
    }).toList();
  }
  
  String _formatMilliseconds(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final ms = milliseconds % 1000;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${seconds}.${(ms ~/ 100)}s';
    }
  }
  
  // Export trim instructions for server processing
  Map<String, dynamic> exportTrimInstructions({
    required String videoPath,
    required List<TrimSegment> segments,
    required Duration videoDuration,
    String? audioPath,
    double? audioVolume,
    double? originalVolume,
  }) {
    final sortedSegments = List<TrimSegment>.from(segments)
      ..sort((a, b) => a.start.compareTo(b.start));
    
    return {
      'version': '1.0',
      'source': {
        'path': videoPath,
        'duration': videoDuration.inMilliseconds,
      },
      'segments': sortedSegments.map((s) => {
        'start': s.start,
        'end': s.end,
        'startMs': (s.start * videoDuration.inMilliseconds).toInt(),
        'endMs': (s.end * videoDuration.inMilliseconds).toInt(),
      }).toList(),
      'audio': audioPath != null ? {
        'path': audioPath,
        'volume': audioVolume ?? 0.7,
        'originalVolume': originalVolume ?? 0.3,
      } : null,
      'output': {
        'format': 'mp4',
        'codec': 'h264',
        'quality': 'high',
      },
    };
  }
}