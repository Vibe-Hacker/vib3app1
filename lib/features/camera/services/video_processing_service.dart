import 'dart:io';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/multi_trim_slider.dart';

class VideoProcessingService {
  static final VideoProcessingService _instance = VideoProcessingService._internal();
  factory VideoProcessingService() => _instance;
  VideoProcessingService._internal();
  
  // Process video with single trim
  Future<String?> trimVideo({
    required String inputPath,
    required double startPercent,
    required double endPercent,
    required Duration videoDuration,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      final startSeconds = startPercent * videoDuration.inSeconds;
      final durationSeconds = (endPercent - startPercent) * videoDuration.inSeconds;
      
      final command = '-ss $startSeconds -i "$inputPath" -t $durationSeconds '
          '-c:v libx264 -preset fast -crf 22 '
          '-c:a aac -b:a 128k '
          '-avoid_negative_ts make_zero '
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('FFmpeg trim failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('Error trimming video: $e');
      return null;
    }
  }
  
  // Process video with multiple trim segments
  Future<String?> multiTrimVideo({
    required String inputPath,
    required List<TrimSegment> segments,
    required Duration videoDuration,
  }) async {
    if (segments.isEmpty) return null;
    
    try {
      final tempDir = await getTemporaryDirectory();
      final segmentFiles = <String>[];
      
      // Step 1: Extract each segment
      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final segmentPath = path.join(
          tempDir.path,
          'segment_${i}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
        
        final startSeconds = segment.start * videoDuration.inSeconds;
        final durationSeconds = (segment.end - segment.start) * videoDuration.inSeconds;
        
        final command = '-ss $startSeconds -i "$inputPath" -t $durationSeconds '
            '-c:v libx264 -preset fast -crf 22 '
            '-c:a aac -b:a 128k '
            '-avoid_negative_ts make_zero '
            '"$segmentPath"';
        
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          segmentFiles.add(segmentPath);
        } else {
          print('Failed to extract segment $i');
          // Clean up created segments
          for (final file in segmentFiles) {
            await File(file).delete();
          }
          return null;
        }
      }
      
      // Step 2: Create concat file
      final concatFilePath = path.join(tempDir.path, 'concat_list.txt');
      final concatFile = File(concatFilePath);
      final concatContent = segmentFiles
          .map((file) => "file '$file'")
          .join('\n');
      await concatFile.writeAsString(concatContent);
      
      // Step 3: Concatenate all segments
      final outputPath = path.join(
        tempDir.path,
        'multi_trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      final concatCommand = '-f concat -safe 0 -i "$concatFilePath" '
          '-c:v libx264 -preset fast -crf 22 '
          '-c:a aac -b:a 128k '
          '"$outputPath"';
      
      final concatSession = await FFmpegKit.execute(concatCommand);
      final concatReturnCode = await concatSession.getReturnCode();
      
      // Clean up temporary files
      for (final file in segmentFiles) {
        await File(file).delete();
      }
      await concatFile.delete();
      
      if (ReturnCode.isSuccess(concatReturnCode)) {
        return outputPath;
      } else {
        print('FFmpeg concat failed with return code: $concatReturnCode');
        return null;
      }
    } catch (e) {
      print('Error multi-trimming video: $e');
      return null;
    }
  }
  
  // Add text overlay to video
  Future<String?> addTextOverlay({
    required String inputPath,
    required String text,
    required double x,
    required double y,
    String fontColor = 'white',
    int fontSize = 48,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'text_overlay_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      // Escape special characters in text
      final escapedText = text.replaceAll(':', '\\:').replaceAll("'", "\\'");
      
      final command = '-i "$inputPath" '
          '-vf "drawtext=text=\'$escapedText\':fontcolor=$fontColor:'
          'fontsize=$fontSize:x=$x:y=$y:box=1:boxcolor=black@0.5:boxborderw=5" '
          '-c:a copy '
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('FFmpeg text overlay failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('Error adding text overlay: $e');
      return null;
    }
  }
  
  // Merge audio with video
  Future<String?> mergeAudioWithVideo({
    required String videoPath,
    required String audioPath,
    double videoVolume = 0.3,
    double audioVolume = 0.7,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'merged_audio_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      final command = '-i "$videoPath" -i "$audioPath" '
          '-filter_complex "[0:a]volume=$videoVolume[a0];'
          '[1:a]volume=$audioVolume[a1];[a0][a1]amerge=inputs=2[aout]" '
          '-map 0:v -map "[aout]" '
          '-c:v copy -c:a aac -b:a 192k '
          '-shortest '
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('FFmpeg audio merge failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('Error merging audio: $e');
      return null;
    }
  }
  
  // Apply video speed
  Future<String?> changeVideoSpeed({
    required String inputPath,
    required double speed,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'speed_${speed}x_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      // Calculate PTS multiplier (inverse of speed)
      final ptsMultiplier = 1.0 / speed;
      
      final command = '-i "$inputPath" '
          '-filter_complex "[0:v]setpts=$ptsMultiplier*PTS[v];'
          '[0:a]atempo=$speed[a]" '
          '-map "[v]" -map "[a]" '
          '-c:v libx264 -preset fast -crf 22 '
          '-c:a aac -b:a 128k '
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('FFmpeg speed change failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('Error changing video speed: $e');
      return null;
    }
  }
  
  // Get video thumbnail at specific time
  Future<String?> getVideoThumbnail({
    required String videoPath,
    required double timePercent,
    required Duration videoDuration,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final timeSeconds = timePercent * videoDuration.inSeconds;
      
      final command = '-ss $timeSeconds -i "$videoPath" '
          '-vframes 1 -q:v 2 '
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('FFmpeg thumbnail extraction failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('Error extracting thumbnail: $e');
      return null;
    }
  }
  
  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      
      await for (final file in dir.list()) {
        if (file is File && 
            (file.path.contains('trimmed_') ||
             file.path.contains('segment_') ||
             file.path.contains('multi_trimmed_') ||
             file.path.contains('text_overlay_') ||
             file.path.contains('merged_audio_') ||
             file.path.contains('speed_') ||
             file.path.contains('thumbnail_'))) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
}