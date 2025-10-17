import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/multi_trim_slider.dart';
import '../services/video_trim_service.dart';

class MultiTrimScreen extends StatefulWidget {
  final VideoPlayerController videoController;
  final Duration videoDuration;
  final List<TrimSegment> initialSegments;
  
  const MultiTrimScreen({
    Key? key,
    required this.videoController,
    required this.videoDuration,
    required this.initialSegments,
  }) : super(key: key);
  
  @override
  State<MultiTrimScreen> createState() => _MultiTrimScreenState();
}

class _MultiTrimScreenState extends State<MultiTrimScreen> with TickerProviderStateMixin {
  late List<TrimSegment> _segments;
  TrimSegment? _currentSegment;
  int? _selectedSegmentIndex;
  bool _isPlaying = false;
  double _addSegmentStart = 0.3;
  double _addSegmentEnd = 0.7;
  List<TrimSegment> _sortedSegments = [];
  
  // Colors for segments
  final List<Color> _segmentColors = [
    AppTheme.primaryColor,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _segments = List.from(widget.initialSegments);
    if (_segments.isEmpty) {
      // Add initial segment that covers only half the video to make it easier to add more
      _segments.add(TrimSegment(
        start: 0.0,
        end: 0.5,
        color: _segmentColors[0],
      ));
    }
    _selectedSegmentIndex = 0;
    widget.videoController.pause();
    widget.videoController.addListener(_videoListener);
  }
  
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.videoController.removeListener(_videoListener);
    super.dispose();
  }
  
  void _videoListener() {
    if (!mounted || !_isPlaying) return;
    
    if (widget.videoController.value.isPlaying && _sortedSegments.isNotEmpty) {
      final currentPosition = widget.videoController.value.position.inMilliseconds;
      final totalDuration = widget.videoDuration.inMilliseconds;
      final normalizedPosition = currentPosition / totalDuration;
      
      // Update UI
      setState(() {});
      
      if (_currentSegment != null) {
        // Check if we've reached the end of current segment
        if (normalizedPosition >= _currentSegment!.end - 0.01) { // Larger buffer for precision
          _playNextSegment();
        }
      }
    }
  }
  
  void _playNextSegment() {
    if (_sortedSegments.isEmpty) return;
    
    final currentIndex = _currentSegment != null 
        ? _sortedSegments.indexOf(_currentSegment!) 
        : -1;
    final nextIndex = currentIndex + 1;
    
    // If we've played all segments, stop
    if (nextIndex >= _sortedSegments.length) {
      widget.videoController.pause();
      setState(() {
        _isPlaying = false;
        _currentSegment = null;
      });
      return;
    }
    
    // Play next segment - immediately jump to its start
    _currentSegment = _sortedSegments[nextIndex];
    _seekToPosition(_currentSegment!.start);
  }
  
  void _togglePlayPause() {
    if (_isPlaying) {
      // Stop playing
      widget.videoController.pause();
      setState(() {
        _isPlaying = false;
        _currentSegment = null;
        _sortedSegments = [];
      });
    } else {
      // Start playing all segments
      if (_segments.isNotEmpty) {
        // Sort segments by start time to play in order
        _sortedSegments = List<TrimSegment>.from(_segments)
          ..sort((a, b) => a.start.compareTo(b.start));
        
        _currentSegment = _sortedSegments[0];
        _seekToPosition(_currentSegment!.start);
        
        setState(() {
          _isPlaying = true;
        });
        
        // Start playback after seek
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isPlaying) {
            widget.videoController.play();
          }
        });
      }
    }
  }
  
  void _playSelectedSegment() {
    if (_selectedSegmentIndex == null || _segments.isEmpty) return;
    
    final segment = _segments[_selectedSegmentIndex!];
    _sortedSegments = [segment]; // Only play this one segment
    _currentSegment = segment;
    _seekToPosition(segment.start);
    widget.videoController.play();
    setState(() {
      _isPlaying = true;
    });
  }
  
  void _seekToPosition(double position) {
    final totalDuration = widget.videoDuration.inMilliseconds;
    final seekPosition = Duration(milliseconds: (totalDuration * position).toInt());
    widget.videoController.seekTo(seekPosition);
  }
  
  void _addSegment() {
    if (_segments.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 8 segments allowed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Find available position
    _findAvailablePosition();
    
    // Immediately add the segment
    final trimService = VideoTrimService();
    final newSegment = TrimSegment(
      start: _addSegmentStart,
      end: _addSegmentEnd,
      color: _segmentColors[_segments.length % _segmentColors.length],
    );
    
    final testSegments = [..._segments, newSegment];
    if (trimService.validateSegments(testSegments)) {
      setState(() {
        _segments.add(newSegment);
        _selectedSegmentIndex = _segments.length - 1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Segment ${_segments.length} added'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Try to find a smaller gap if overlap detected
      final gapSize = _addSegmentEnd - _addSegmentStart;
      _addSegmentStart = _addSegmentStart + gapSize * 0.1;
      _addSegmentEnd = _addSegmentEnd - gapSize * 0.1;
      
      final retrySegment = TrimSegment(
        start: _addSegmentStart,
        end: _addSegmentEnd,
        color: _segmentColors[_segments.length % _segmentColors.length],
      );
      
      final retrySegments = [..._segments, retrySegment];
      if (trimService.validateSegments(retrySegments)) {
        setState(() {
          _segments.add(retrySegment);
          _selectedSegmentIndex = _segments.length - 1;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Segment ${_segments.length} added'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No space available for new segment'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _findAvailablePosition() {
    // Always add new segments at a visible position that can be adjusted
    // Start at 40% and end at 60% of the video by default
    _addSegmentStart = 0.4;
    _addSegmentEnd = 0.6;
    
    // If this overlaps with existing segments, try to find a better position
    final trimService = VideoTrimService();
    final testSegment = TrimSegment(
      start: _addSegmentStart,
      end: _addSegmentEnd,
      color: Colors.white,
    );
    
    final testSegments = [..._segments, testSegment];
    if (!trimService.validateSegments(testSegments)) {
      // Try different positions
      final positions = [
        [0.2, 0.4],  // Early in video
        [0.6, 0.8],  // Late in video
        [0.0, 0.2],  // Very start
        [0.8, 1.0],  // Very end
        [0.3, 0.5],  // Mid-early
        [0.5, 0.7],  // Mid-late
      ];
      
      for (final pos in positions) {
        _addSegmentStart = pos[0];
        _addSegmentEnd = pos[1];
        final testSeg = TrimSegment(
          start: _addSegmentStart,
          end: _addSegmentEnd,
          color: Colors.white,
        );
        final test = [..._segments, testSeg];
        if (trimService.validateSegments(test)) {
          break;
        }
      }
    }
  }
  
  void _deleteSegment(int index) {
    if (_segments.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must have at least one segment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _segments.removeAt(index);
      if (_selectedSegmentIndex == index) {
        _selectedSegmentIndex = _segments.isEmpty ? null : 0;
      } else if (_selectedSegmentIndex != null && _selectedSegmentIndex! > index) {
        _selectedSegmentIndex = _selectedSegmentIndex! - 1;
      }
    });
  }
  
  void _updateSegment(int index, double newStart, double newEnd) {
    // Ensure minimum segment size
    if (newEnd - newStart < 0.05) {
      return;
    }
    
    // Allow segments to be moved freely without any overlap restrictions
    setState(() {
      _segments[index] = TrimSegment(
        start: newStart,
        end: newEnd,
        color: _segments[index].color,
      );
    });
  }
  
  double _getTotalDuration() {
    final trimService = VideoTrimService();
    return trimService.calculateTotalDuration(_segments, widget.videoDuration);
  }
  
  void _confirmSegments() {
    Navigator.pop(context, {
      'segments': _segments,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    // Calculate heights for all sections to fit on one screen
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final headerHeight = 50.0;
    final videoHeight = availableHeight * 0.28;
    final timelineHeight = 60.0;
    final segmentsHeight = 70.0;
    final controlsHeight = availableHeight - headerHeight - videoHeight - timelineHeight - segmentsHeight - 24; // 24 for margins
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Multi-Trim Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_getTotalDuration().toStringAsFixed(1)}s total',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _confirmSegments,
                    icon: const Icon(Icons.check, color: AppTheme.primaryColor, size: 26),
                  ),
                ],
              ),
            ),
            
            // Video Preview
            Container(
              height: videoHeight,
              width: screenWidth,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: VideoPlayer(widget.videoController),
                    ),
                  ),
                  
                  // Play/Pause button overlay
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Timeline
            Container(
              height: timelineHeight,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: List.generate(10, (index) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    // Segments overlay
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _SegmentsPainter(
                            segments: _segments,
                            selectedIndex: _selectedSegmentIndex,
                            currentPosition: widget.videoController.value.isInitialized
                                ? widget.videoController.value.position.inMilliseconds / 
                                  widget.videoDuration.inMilliseconds
                                : 0.0,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              final width = constraints.maxWidth;
                              final normalizedX = details.localPosition.dx / width;
                              
                              // Check which segment was tapped
                              for (int i = 0; i < _segments.length; i++) {
                                if (normalizedX >= _segments[i].start && 
                                    normalizedX <= _segments[i].end) {
                                  setState(() {
                                    _selectedSegmentIndex = i;
                                  });
                                  break;
                                }
                              }
                            },
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Segment List
            Container(
              height: segmentsHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Segments (${_segments.length}/8)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_segments.length < 8)
                        TextButton.icon(
                          onPressed: _addSegment,
                          icon: const Icon(Icons.add, color: AppTheme.primaryColor, size: 16),
                          label: const Text(
                            'Add',
                            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _segments.length,
                      itemBuilder: (context, index) {
                        final segment = _segments[index];
                        final duration = (segment.end - segment.start) * widget.videoDuration.inSeconds;
                        final isSelected = index == _selectedSegmentIndex;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSegmentIndex = index;
                            });
                          },
                          child: Container(
                            width: 52,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? segment.color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: segment.color,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? Icons.edit : Icons.check_circle,
                                  color: segment.color,
                                  size: 12,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'S${index + 1}',
                                  style: TextStyle(
                                    color: segment.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                                Text(
                                  '${duration.toStringAsFixed(1)}s',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Bottom Controls - Dynamic content based on state
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _selectedSegmentIndex != null
                      ? _buildCompactSegmentEditor(_selectedSegmentIndex!)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white30,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Select a segment to edit',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'or tap + to add a new segment',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactSegmentEditor(int index) {
    final segment = _segments[index];
    final totalSeconds = widget.videoDuration.inSeconds.toDouble();
    final startSeconds = segment.start * totalSeconds;
    final endSeconds = segment.end * totalSeconds;
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: segment.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: segment.color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Segment ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteSegment(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Trim slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: RangeSlider(
              values: RangeValues(segment.start, segment.end),
              onChanged: (values) {
                _updateSegment(index, values.start, values.end);
                _seekToPosition(values.start);
              },
              activeColor: segment.color,
              inactiveColor: Colors.white24,
            ),
          ),
          
          // Time labels
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(color: Colors.white60, fontSize: 8),
                    ),
                    Text(
                      _formatTime(startSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: segment.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(endSeconds - startSeconds).toStringAsFixed(1)}s',
                    style: TextStyle(
                      color: segment.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'End',
                      style: TextStyle(color: Colors.white60, fontSize: 8),
                    ),
                    Text(
                      _formatTime(endSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Action button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              onPressed: _playSelectedSegment,
              icon: const Icon(Icons.play_arrow, size: 14),
              label: const Text('Preview Segment', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: segment.color,
                side: BorderSide(color: segment.color, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(double seconds) {
    final minutes = seconds ~/ 60;
    final secs = (seconds % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _SegmentsPainter extends CustomPainter {
  final List<TrimSegment> segments;
  final int? selectedIndex;
  final double currentPosition;
  
  _SegmentsPainter({
    required this.segments,
    required this.selectedIndex,
    required this.currentPosition,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw segments
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isSelected = i == selectedIndex;
      
      final left = segment.start * size.width;
      final right = segment.end * size.width;
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left + 2, 8, right - 2, size.height - 8),
        Radius.circular(4),
      );
      
      // Fill
      paint.color = segment.color.withOpacity(0.3);
      canvas.drawRRect(rect, paint);
      
      // Border
      paint
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;
      canvas.drawRRect(rect, paint);
      
      // Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSelected ? 12 : 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        (left + right - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
    
    // Draw position indicator
    if (currentPosition > 0) {
      final x = currentPosition * size.width;
      paint
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  Path _createDashedPath(Path source) {
    final dashPath = Path();
    final dashWidth = 5.0;
    final dashSpace = 3.0;
    var distance = 0.0;
    
    for (final metric in source.computeMetrics()) {
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(
          metric.extractPath(start, end),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    
    return dashPath;
  }
  
  @override
  bool shouldRepaint(_SegmentsPainter oldDelegate) {
    return segments != oldDelegate.segments ||
           selectedIndex != oldDelegate.selectedIndex ||
           currentPosition != oldDelegate.currentPosition;
  }
}