import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_theme.dart';

class TrimSegment {
  final double start;
  final double end;
  final Color color;
  
  TrimSegment({
    required this.start,
    required this.end,
    required this.color,
  });
}

class MultiTrimSlider extends StatefulWidget {
  final VideoPlayerController videoController;
  final Duration videoDuration;
  final List<TrimSegment> initialSegments;
  final Function(List<TrimSegment>) onSegmentsChanged;
  final VoidCallback onClose;
  
  const MultiTrimSlider({
    Key? key,
    required this.videoController,
    required this.videoDuration,
    required this.initialSegments,
    required this.onSegmentsChanged,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<MultiTrimSlider> createState() => _MultiTrimSliderState();
}

class _MultiTrimSliderState extends State<MultiTrimSlider> with TickerProviderStateMixin {
  late List<TrimSegment> _segments;
  TrimSegment? _currentSegment;
  int? _selectedSegmentIndex;
  bool _isPlaying = false;
  bool _isAddingSegment = false;
  double _addSegmentStart = 0.3;
  double _addSegmentEnd = 0.7;
  
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
    _segments = List.from(widget.initialSegments);
    if (_segments.isEmpty) {
      // Add initial segment
      _segments.add(TrimSegment(
        start: 0.0,
        end: 1.0,
        color: _segmentColors[0],
      ));
    }
    _selectedSegmentIndex = 0;
    widget.videoController.pause();
    widget.videoController.addListener(_videoListener);
  }
  
  @override
  void dispose() {
    widget.videoController.removeListener(_videoListener);
    if (!_isPlaying) {
      widget.videoController.play();
    }
    super.dispose();
  }
  
  void _videoListener() {
    if (widget.videoController.value.isPlaying && mounted) {
      setState(() {});
      
      // Check if we need to jump to next segment
      if (_isPlaying && _currentSegment != null) {
        final currentPosition = widget.videoController.value.position.inMilliseconds;
        final totalDuration = widget.videoDuration.inMilliseconds;
        final normalizedPosition = currentPosition / totalDuration;
        
        if (normalizedPosition >= _currentSegment!.end) {
          _playNextSegment();
        }
      }
    }
  }
  
  void _playNextSegment() {
    if (_segments.isEmpty) return;
    
    final currentIndex = _currentSegment != null 
        ? _segments.indexOf(_currentSegment!) 
        : -1;
    final nextIndex = (currentIndex + 1) % _segments.length;
    
    _currentSegment = _segments[nextIndex];
    _seekToPosition(_currentSegment!.start);
  }
  
  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        widget.videoController.pause();
        _currentSegment = null;
      } else {
        // Start playing from first segment
        if (_segments.isNotEmpty) {
          _currentSegment = _segments[0];
          _seekToPosition(_currentSegment!.start);
          widget.videoController.play();
        }
      }
      _isPlaying = !_isPlaying;
    });
  }
  
  void _playSelectedSegment() {
    if (_selectedSegmentIndex == null || _segments.isEmpty) return;
    
    final segment = _segments[_selectedSegmentIndex!];
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
    setState(() {
      _isAddingSegment = true;
      // Find a good position for new segment
      _findAvailablePosition();
    });
  }
  
  void _findAvailablePosition() {
    // Sort segments by start position
    final sortedSegments = List<TrimSegment>.from(_segments)
      ..sort((a, b) => a.start.compareTo(b.start));
    
    // Find gaps between segments
    double gapStart = 0.0;
    double gapEnd = 1.0;
    bool foundGap = false;
    
    for (int i = 0; i < sortedSegments.length; i++) {
      final segment = sortedSegments[i];
      
      // Check gap before this segment
      if (segment.start - gapStart > 0.1) {
        gapEnd = segment.start;
        foundGap = true;
        break;
      }
      
      gapStart = segment.end;
    }
    
    // Check gap after last segment
    if (!foundGap && gapStart < 0.9) {
      gapEnd = 1.0;
      foundGap = true;
    }
    
    if (foundGap) {
      final gapSize = gapEnd - gapStart;
      _addSegmentStart = gapStart + gapSize * 0.2;
      _addSegmentEnd = gapStart + gapSize * 0.8;
    }
  }
  
  void _confirmAddSegment() {
    if (_addSegmentStart >= _addSegmentEnd) return;
    
    // Check for overlaps
    bool hasOverlap = false;
    for (final segment in _segments) {
      if ((_addSegmentStart >= segment.start && _addSegmentStart <= segment.end) ||
          (_addSegmentEnd >= segment.start && _addSegmentEnd <= segment.end) ||
          (_addSegmentStart <= segment.start && _addSegmentEnd >= segment.end)) {
        hasOverlap = true;
        break;
      }
    }
    
    if (!hasOverlap) {
      setState(() {
        final newSegment = TrimSegment(
          start: _addSegmentStart,
          end: _addSegmentEnd,
          color: _segmentColors[_segments.length % _segmentColors.length],
        );
        _segments.add(newSegment);
        _selectedSegmentIndex = _segments.length - 1;
        _isAddingSegment = false;
        widget.onSegmentsChanged(_segments);
      });
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Segments cannot overlap'),
          backgroundColor: Colors.red,
        ),
      );
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
      widget.onSegmentsChanged(_segments);
    });
  }
  
  void _updateSegment(int index, double newStart, double newEnd) {
    // Check for overlaps with other segments
    bool hasOverlap = false;
    for (int i = 0; i < _segments.length; i++) {
      if (i == index) continue;
      final segment = _segments[i];
      if ((newStart >= segment.start && newStart <= segment.end) ||
          (newEnd >= segment.start && newEnd <= segment.end) ||
          (newStart <= segment.start && newEnd >= segment.end)) {
        hasOverlap = true;
        break;
      }
    }
    
    if (!hasOverlap) {
      setState(() {
        _segments[index] = TrimSegment(
          start: newStart,
          end: newEnd,
          color: _segments[index].color,
        );
        widget.onSegmentsChanged(_segments);
      });
    }
  }
  
  double _getTotalDuration() {
    double total = 0;
    for (final segment in _segments) {
      total += (segment.end - segment.start) * widget.videoDuration.inSeconds;
    }
    return total;
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Video Preview
            Flexible(
              flex: 2,
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: widget.videoController.value.aspectRatio,
                          child: VideoPlayer(widget.videoController),
                        ),
                      ),
                    ),
                  ),
                  
                  // Play/Pause button overlay
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Controls
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Multi-Trim Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${_getTotalDuration().toStringAsFixed(1)}s total',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.check, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Add segment button
                    if (!_isAddingSegment)
                      ElevatedButton.icon(
                        onPressed: _segments.length < 8 ? _addSegment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Segment'),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Timeline
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Background thumbnails
                          Row(
                            children: List.generate(10, (index) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }),
                          ),
                          
                          // Segments
                          ..._segments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final segment = entry.value;
                            final isSelected = index == _selectedSegmentIndex;
                            
                            return Positioned(
                              left: segment.start * (MediaQuery.of(context).size.width - 80),
                              right: (1 - segment.end) * (MediaQuery.of(context).size.width - 80),
                              top: 10,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSegmentIndex = index;
                                  });
                                  _playSelectedSegment();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: segment.color.withOpacity(0.3),
                                    border: Border.all(
                                      color: segment.color,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${(index + 1)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSelected ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          
                          // Add segment preview
                          if (_isAddingSegment)
                            Positioned(
                              left: _addSegmentStart * (MediaQuery.of(context).size.width - 80),
                              right: (1 - _addSegmentEnd) * (MediaQuery.of(context).size.width - 80),
                              top: 10,
                              bottom: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.yellow,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.yellow,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Position indicator
                          if (widget.videoController.value.isInitialized)
                            Positioned(
                              left: _getCurrentPositionOffset(),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Segment editor
                    if (_selectedSegmentIndex != null && !_isAddingSegment)
                      _buildSegmentEditor(_selectedSegmentIndex!),
                    
                    // Add segment controls
                    if (_isAddingSegment)
                      _buildAddSegmentControls(),
                    
                    const SizedBox(height: 16),
                    
                    // Segments list
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _segments.length,
                        itemBuilder: (context, index) {
                          final segment = _segments[index];
                          final duration = (segment.end - segment.start) * 
                              widget.videoDuration.inSeconds;
                          final isSelected = index == _selectedSegmentIndex;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSegmentIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? segment.color.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: segment.color,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Segment ${index + 1}',
                                    style: TextStyle(
                                      color: segment.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${duration.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSegmentEditor(int index) {
    final segment = _segments[index];
    final totalSeconds = widget.videoDuration.inSeconds.toDouble();
    final startSeconds = segment.start * totalSeconds;
    final endSeconds = segment.end * totalSeconds;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: segment.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Segment ${index + 1}',
                style: TextStyle(
                  color: segment.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _deleteSegment(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(segment.start, segment.end),
            onChanged: (values) {
              _updateSegment(index, values.start, values.end);
              _seekToPosition(values.start);
            },
            activeColor: segment.color,
            inactiveColor: Colors.white24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(startSeconds),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                _formatTime(endSeconds),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddSegmentControls() {
    final totalSeconds = widget.videoDuration.inSeconds.toDouble();
    final startSeconds = _addSegmentStart * totalSeconds;
    final endSeconds = _addSegmentEnd * totalSeconds;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'New Segment',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: RangeValues(_addSegmentStart, _addSegmentEnd),
            onChanged: (values) {
              setState(() {
                _addSegmentStart = values.start;
                _addSegmentEnd = values.end;
              });
              _seekToPosition(values.start);
            },
            activeColor: Colors.yellow,
            inactiveColor: Colors.white24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(startSeconds),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                _formatTime(endSeconds),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAddingSegment = false;
                  });
                },
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _confirmAddSegment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ],
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
  
  double _getCurrentPositionOffset() {
    if (!widget.videoController.value.isInitialized) return 0;
    
    final currentPosition = widget.videoController.value.position.inMilliseconds;
    final totalDuration = widget.videoDuration.inMilliseconds;
    final normalizedPosition = currentPosition / totalDuration;
    
    final timelineWidth = MediaQuery.of(context).size.width - 80;
    
    return normalizedPosition * timelineWidth;
  }
}