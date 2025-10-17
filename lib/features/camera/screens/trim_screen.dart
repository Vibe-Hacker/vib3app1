import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class TrimScreen extends StatefulWidget {
  final VideoPlayerController videoController;
  final Duration videoDuration;
  final double initialTrimStart;
  final double initialTrimEnd;
  
  const TrimScreen({
    Key? key,
    required this.videoController,
    required this.videoDuration,
    this.initialTrimStart = 0.0,
    this.initialTrimEnd = 1.0,
  }) : super(key: key);
  
  @override
  State<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends State<TrimScreen> with TickerProviderStateMixin {
  late double _start;
  late double _end;
  bool _isDragging = false;
  bool _isPlaying = false;
  late AnimationController _playbackController;
  late Animation<double> _playbackAnimation;
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _start = widget.initialTrimStart;
    _end = widget.initialTrimEnd;
    
    // Pause the video when trim screen opens
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.videoController.removeListener(_videoListener);
    _playbackController.dispose();
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
  
  void _confirmTrim() {
    // Return the trim values
    Navigator.pop(context, {
      'trimStart': _start,
      'trimEnd': _end,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.videoDuration.inSeconds.toDouble();
    final startSeconds = _start * totalSeconds;
    final endSeconds = _end * totalSeconds;
    final durationSeconds = endSeconds - startSeconds;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Trim Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${durationSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _confirmTrim,
                    icon: const Icon(Icons.check, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            
            // Video Preview
            Expanded(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: widget.videoController.value.aspectRatio,
                          child: VideoPlayer(widget.videoController),
                        ),
                      ),
                      
                      // Play/Pause button overlay
                      Container(
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
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trim Controls
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Video timeline with thumbnails
                  Container(
                    height: 80,
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
                            left: _getCurrentPositionOffset(context),
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
                        'Duration: ${durationSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
  
  double _getCurrentPositionOffset(BuildContext context) {
    if (!widget.videoController.value.isInitialized) return 0;
    
    final currentPosition = widget.videoController.value.position.inMilliseconds;
    final totalDuration = widget.videoDuration.inMilliseconds;
    final normalizedPosition = currentPosition / totalDuration;
    
    // Get the width of the timeline container
    final timelineWidth = MediaQuery.of(context).size.width - 40; // 20px margin on each side
    
    return normalizedPosition * timelineWidth;
  }
}