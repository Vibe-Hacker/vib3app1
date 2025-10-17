import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../app/theme/app_theme.dart';
import 'enhanced_camera_screen.dart';
import '../widgets/multi_trim_slider.dart';
import '../widgets/text_overlay_editor.dart' as text_editor;
import '../widgets/sticker_picker.dart';
import '../widgets/music_picker.dart';
import '../services/video_trim_service.dart';
import 'trim_screen.dart';
import 'multi_trim_screen.dart';

class VideoEditScreen extends StatefulWidget {
  final List<VideoSegment> segments;
  
  const VideoEditScreen({
    Key? key,
    required this.segments,
  }) : super(key: key);
  
  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  
  // Edit tools state
  bool _showTextEditor = false;
  bool _showStickerPicker = false;
  bool _showMusicPicker = false;
  
  // Text overlays
  final List<TextOverlay> _textOverlays = [];
  
  // Trim segments for multi-trim
  final List<TrimSegment> _trimSegments = [];
  
  // Stickers
  final List<StickerOverlay> _stickers = [];
  
  // Audio
  String? _selectedAudioPath;
  double _audioVolume = 0.5;
  double _originalVolume = 0.3;
  
  // Trim
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  
  // Tab controller for bottom tools
  late TabController _toolsTabController;
  
  @override
  void initState() {
    super.initState();
    _toolsTabController = TabController(length: 5, vsync: this);
    _initializeVideo();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _toolsTabController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideo() async {
    if (widget.segments.isEmpty) return;
    
    // For now, play the first segment
    // TODO: Merge all segments into one video
    final firstSegment = widget.segments.first;
    _videoController = VideoPlayerController.file(File(firstSegment.path))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
      });
  }
  
  void _togglePlayPause() {
    if (_videoController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }
  
  void _saveAndContinue() async {
    // Save trim data if multi-trim is used
    String? trimJobId;
    if (_trimSegments.isNotEmpty && _videoController != null) {
      trimJobId = await VideoTrimService().saveTrimData(
        videoPath: widget.segments.first.path,
        segments: _trimSegments,
        videoDuration: _videoController!.value.duration,
      );
    }
    
    // Navigate to caption/share screen
    context.push('/video-share', extra: {
      'videoPath': widget.segments.first.path,
      'textOverlays': _textOverlays,
      'stickers': _stickers,
      'audioPath': _selectedAudioPath,
      'audioVolume': _audioVolume,
      'originalVolume': _originalVolume,
      'trimStart': _trimStart,
      'trimEnd': _trimEnd,
      'trimSegments': _trimSegments,
      'trimJobId': trimJobId,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video preview
          _buildVideoPreview(),
          
          // Text overlays
          ..._textOverlays.map((overlay) => text_editor.TextOverlayWidget(
            overlay: text_editor.TextOverlay(
              text: overlay.text,
              style: overlay.style,
              position: overlay.position,
            ),
            onUpdate: (updated) {
              setState(() {
                final index = _textOverlays.indexOf(overlay);
                _textOverlays[index] = TextOverlay(
                  text: updated.text,
                  style: updated.style,
                  position: updated.position,
                );
              });
            },
            onDelete: () {
              setState(() {
                _textOverlays.remove(overlay);
              });
            },
          )),
          
          // Stickers
          ..._stickers.map((sticker) => StickerWidget(
            sticker: sticker,
            onUpdate: (updated) {
              setState(() {
                final index = _stickers.indexOf(sticker);
                _stickers[index] = updated;
              });
            },
            onDelete: () {
              setState(() {
                _stickers.remove(sticker);
              });
            },
          )),
          
          // Top controls
          _buildTopControls(),
          
          // Bottom editing tools
          _buildBottomTools(),
          
          // Tool panels
          if (_showTextEditor) _buildTextEditor(),
          if (_showStickerPicker) _buildStickerPicker(),
          if (_showMusicPicker) _buildMusicPicker(),
        ],
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }
    
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              
              // Play/pause overlay
              AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              
              // Title
              const Text(
                'Edit Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Save button
              TextButton(
                onPressed: _saveAndContinue,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomTools() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tool tabs
              TabBar(
                controller: _toolsTabController,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(icon: Icon(Icons.music_note), text: 'Sound'),
                  Tab(icon: Icon(Icons.text_fields), text: 'Text'),
                  Tab(icon: Icon(Icons.emoji_emotions), text: 'Stickers'),
                  Tab(icon: Icon(Icons.content_cut), text: 'Trim'),
                  Tab(icon: Icon(Icons.filter_vintage), text: 'Effects'),
                ],
              ),
              
              // Tool content
              SizedBox(
                height: 80,
                child: TabBarView(
                  controller: _toolsTabController,
                  children: [
                    // Sound tools
                    _buildSoundTools(),
                    
                    // Text tools
                    _buildTextTools(),
                    
                    // Sticker tools
                    _buildStickerTools(),
                    
                    // Trim tools
                    _buildTrimTools(),
                    
                    // Effect tools
                    _buildEffectTools(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSoundTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.library_music,
          label: 'Add Sound',
          onTap: () {
            setState(() {
              _showMusicPicker = true;
            });
          },
        ),
        _buildToolButton(
          icon: Icons.volume_up,
          label: 'Volume',
          onTap: () {
            _showVolumeControls();
          },
        ),
        _buildToolButton(
          icon: Icons.mic,
          label: 'Voiceover',
          onTap: () {
            // TODO: Record voiceover
          },
        ),
      ],
    );
  }
  
  Widget _buildTextTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.title,
          label: 'Add Text',
          onTap: () {
            setState(() {
              _showTextEditor = true;
            });
          },
        ),
        _buildToolButton(
          icon: Icons.format_color_text,
          label: 'Styles',
          onTap: () {
            // TODO: Show text styles
          },
        ),
        _buildToolButton(
          icon: Icons.animation,
          label: 'Animate',
          onTap: () {
            // TODO: Text animations
          },
        ),
      ],
    );
  }
  
  Widget _buildStickerTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.emoji_emotions,
          label: 'Stickers',
          onTap: () {
            setState(() {
              _showStickerPicker = true;
            });
          },
        ),
        _buildToolButton(
          icon: Icons.gif,
          label: 'GIFs',
          onTap: () {
            // TODO: Show GIF picker
          },
        ),
        _buildToolButton(
          icon: Icons.draw,
          label: 'Draw',
          onTap: () {
            // TODO: Drawing tool
          },
        ),
      ],
    );
  }
  
  Widget _buildTrimTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.content_cut,
          label: 'Trim',
          onTap: () async {
            if (_videoController == null || !_videoController!.value.isInitialized) return;
            
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => TrimScreen(
                  videoController: _videoController!,
                  videoDuration: _videoController!.value.duration,
                  initialTrimStart: _trimStart,
                  initialTrimEnd: _trimEnd,
                ),
              ),
            );
            
            if (result != null) {
              setState(() {
                _trimStart = result['trimStart'];
                _trimEnd = result['trimEnd'];
              });
            }
          },
        ),
        _buildToolButton(
          icon: Icons.splitscreen,
          label: 'Multi-Trim',
          onTap: () async {
            if (_videoController == null || !_videoController!.value.isInitialized) return;
            
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => MultiTrimScreen(
                  videoController: _videoController!,
                  videoDuration: _videoController!.value.duration,
                  initialSegments: _trimSegments,
                ),
              ),
            );
            
            if (result != null && result['segments'] != null) {
              setState(() {
                _trimSegments.clear();
                _trimSegments.addAll(result['segments'] as List<TrimSegment>);
              });
            }
          },
        ),
        _buildToolButton(
          icon: Icons.speed,
          label: 'Speed',
          onTap: () {
            // TODO: Adjust speed
          },
        ),
      ],
    );
  }
  
  Widget _buildEffectTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.filter_vintage,
          label: 'Filters',
          onTap: () {
            // TODO: Show filters
          },
        ),
        _buildToolButton(
          icon: Icons.auto_awesome,
          label: 'Effects',
          onTap: () {
            // TODO: Show effects
          },
        ),
        _buildToolButton(
          icon: Icons.view_carousel,
          label: 'Transitions',
          onTap: () {
            // TODO: Show transitions
          },
        ),
      ],
    );
  }
  
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextEditor() {
    return text_editor.TextOverlayEditor(
      onSave: (text, style) {
        setState(() {
          _textOverlays.add(TextOverlay(
            text: text,
            style: style,
            position: const Offset(0.5, 0.5),
          ));
          _showTextEditor = false;
        });
      },
      onCancel: () {
        setState(() {
          _showTextEditor = false;
        });
      },
    );
  }
  
  Widget _buildStickerPicker() {
    return StickerPicker(
      onStickerSelected: (sticker) {
        setState(() {
          _stickers.add(StickerOverlay(
            sticker: sticker,
            position: const Offset(0.5, 0.5),
            scale: 1.0,
            rotation: 0.0,
          ));
          _showStickerPicker = false;
        });
      },
      onClose: () {
        setState(() {
          _showStickerPicker = false;
        });
      },
    );
  }
  
  Widget _buildMusicPicker() {
    return MusicPicker(
      onMusicSelected: (track) {
        setState(() {
          _selectedAudioPath = track.audioUrl;
          _showMusicPicker = false;
        });
        // TODO: Actually apply the music to the video
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${track.title} by ${track.artist}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      },
      onClose: () {
        setState(() {
          _showMusicPicker = false;
        });
      },
    );
  }
  
  
  void _showVolumeControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVolumeSlider(
              label: 'Sound Volume',
              value: _audioVolume,
              onChanged: (value) {
                setState(() {
                  _audioVolume = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildVolumeSlider(
              label: 'Original Sound',
              value: _originalVolume,
              onChanged: (value) {
                setState(() {
                  _originalVolume = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.volume_down, color: Colors.white54),
            Expanded(
              child: Slider(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primaryColor,
                inactiveColor: Colors.white24,
              ),
            ),
            const Icon(Icons.volume_up, color: Colors.white54),
          ],
        ),
      ],
    );
  }
}

// Models
class TextOverlay {
  final String text;
  final TextStyle style;
  Offset position;
  
  TextOverlay({
    required this.text,
    required this.style,
    required this.position,
  });
}

class StickerOverlay {
  final String sticker;
  Offset position;
  double scale;
  double rotation;
  
  StickerOverlay({
    required this.sticker,
    required this.position,
    required this.scale,
    required this.rotation,
  });
}