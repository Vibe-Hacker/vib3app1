import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_theme.dart';

class TrimSlider extends StatefulWidget {
  final VideoPlayerController videoController;
  final Duration videoDuration;
  final double trimStart;
  final double trimEnd;
  final Function(double, double) onTrimChanged;
  final VoidCallback onClose;
  
  const TrimSlider({
    Key? key,
    required this.videoController,
    required this.videoDuration,
    required this.trimStart,
    required this.trimEnd,
    required this.onTrimChanged,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider> with TickerProviderStateMixin {
  late double _start;
  late double _end;
  bool _isDragging = false;
  bool _isPlaying = false;
  late AnimationController _playbackController;
  late Animation<double> _playbackAnimation;
  
  @override
  void initState() {
    super.initState();
    _start = widget.trimStart;
    _end = widget.trimEnd;
    // Pause the video when trim slider opens
    widget.videoController.pause();
    
    // Setup playback animation for position indicator
    _playbackController = AnimationController(
      duration: Duration(seconds: 0),
      vsync: this,
    );
    _updatePlaybackAnimation();
    
    // Listen to video position
    widget.videoController.addListener(_videoListener);
  }
  
  @override
  void dispose() {
    widget.videoController.removeListener(_videoListener);
    _playbackController.dispose();
    // Resume video when closing
    if (!_isDragging && !_isPlaying) {
      widget.videoController.play();
    }
    super.dispose();
  }
  
  void _videoListener() {
    if (widget.videoController.value.isPlaying && mounted) {
      setState(() {});
      
      // Stop at the end of trimmed section
      final currentPosition = widget.videoController.value.position.inMilliseconds;
      final totalDuration = widget.videoDuration.inMilliseconds;
      final normalizedPosition = currentPosition / totalDuration;
      
      if (normalizedPosition >= _end && _isPlaying) {
        widget.videoController.pause();
        _seekToPosition(_start);
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }
  
  void _updatePlaybackAnimation() {
    final duration = (_end - _start) * widget.videoDuration.inMilliseconds;
    _playbackController.duration = Duration(milliseconds: duration.toInt());
    _playbackAnimation = Tween<double>(
      begin: _start,
      end: _end,
    ).animate(_playbackController);
  }
  
  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        widget.videoController.pause();
        _playbackController.stop();
      } else {
        // Start from beginning of trimmed section
        _seekToPosition(_start);
        widget.videoController.play();
        _playbackController.forward(from: 0);
      }
      _isPlaying = !_isPlaying;
    });
  }
  
  void _seekToPosition(double position) {
    final totalDuration = widget.videoDuration.inMilliseconds;
    final seekPosition = Duration(milliseconds: (totalDuration * position).toInt());
    widget.videoController.seekTo(seekPosition);
  }
  
  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.videoDuration.inSeconds.toDouble();
    final startSeconds = _start * totalSeconds;
    final endSeconds = _end * totalSeconds;
    final durationSeconds = endSeconds - startSeconds;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: widget.videoController.value.aspectRatio,
                        child: VideoPlayer(widget.videoController),
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
            
            // Trim controls
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trim Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${durationSeconds.toStringAsFixed(1)}s',
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
            
            const SizedBox(height: 24),
            
            // Video timeline with thumbnails
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Thumbnails placeholder
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
                  
                  // Trim overlay
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Left trimmed area
                        if (_start > 0)
                          Expanded(
                            flex: (_start * 1000).toInt(),
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        
                        // Selected area
                        Expanded(
                          flex: ((_end - _start) * 1000).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        
                        // Right trimmed area
                        if (_end < 1)
                          Expanded(
                            flex: ((1 - _end) * 1000).toInt(),
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Current position indicator
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
            
            const SizedBox(height: 24),
            
            // Trim handles
            RangeSlider(
              values: RangeValues(_start, _end),
              onChangeStart: (values) {
                setState(() {
                  _isDragging = true;
                });
                widget.videoController.pause();
              },
              onChanged: (values) {
                setState(() {
                  _start = values.start;
                  _end = values.end;
                });
                widget.onTrimChanged(_start, _end);
                _updatePlaybackAnimation();
                // Seek to the current position being dragged
                final currentPosition = values.end - _end > 0.01 ? values.end : values.start;
                _seekToPosition(currentPosition);
              },
              onChangeEnd: (values) {
                setState(() {
                  _isDragging = false;
                });
                // Seek to start of trimmed section
                _seekToPosition(_start);
              },
              activeColor: AppTheme.primaryColor,
              inactiveColor: Colors.white24,
              labels: RangeLabels(
                _formatTime(startSeconds),
                _formatTime(endSeconds),
              ),
            ),
            
            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(startSeconds),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(endSeconds),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
                ],
              ),
            ),
          ],
        ),
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
    
    // Get the width of the timeline container
    final timelineWidth = MediaQuery.of(context).size.width - 40; // 20px margin on each side
    
    return normalizedPosition * timelineWidth;
  }
}