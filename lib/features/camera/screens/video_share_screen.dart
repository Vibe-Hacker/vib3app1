import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import 'video_edit_screen.dart';

class VideoShareScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;
  
  const VideoShareScreen({
    Key? key,
    required this.videoData,
  }) : super(key: key);
  
  @override
  State<VideoShareScreen> createState() => _VideoShareScreenState();
}

class _VideoShareScreenState extends State<VideoShareScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final PostService _postService = PostService();
  late final AuthService _authService;
  
  VideoPlayerController? _videoController;
  final List<String> _tags = [];
  bool _allowComments = true;
  bool _allowDuet = true;
  bool _allowStitch = true;
  bool _allowDownload = true;
  String _visibility = 'public'; // public, friends, private
  bool _isUploading = false;
  
  // Thumbnail selection
  int _selectedThumbnailIndex = 0;
  final List<String> _thumbnailPaths = []; // Would be generated from video
  
  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _initializeVideo();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideo() async {
    final videoPath = widget.videoData['videoPath'] as String;
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      });
  }
  
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }
  
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }
  
  Future<void> _publishVideo() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // TODO: Process video with edits
      // TODO: Upload video file to storage
      // TODO: Generate and upload thumbnail
      
      // Create post
      await _postService.createPost(
        userId: user.id,
        content: _captionController.text.trim(),
        mediaUrl: widget.videoData['videoPath'], // This would be the uploaded URL
        mediaType: 'video',
        aspectRatio: _videoController?.value.aspectRatio ?? 9/16,
        thumbnailUrl: '', // This would be the uploaded thumbnail URL
        tags: _tags,
        visibility: _visibility,
        allowComments: _allowComments,
        allowDuet: _allowDuet,
        allowStitch: _allowStitch,
        allowDownload: _allowDownload,
      );
      
      // Navigate back to home
      context.go('/home');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: _isUploading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Share Video',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _publishVideo,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video preview and caption
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video thumbnail
                  Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _videoController != null &&
                              _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Caption input
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      maxLength: 150,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Describe your video...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24),
            
            // Tags
            _buildTagsSection(),
            
            const Divider(color: Colors.white24),
            
            // Cover/Thumbnail selector
            _buildThumbnailSelector(),
            
            const Divider(color: Colors.white24),
            
            // Privacy settings
            _buildPrivacySettings(),
            
            const Divider(color: Colors.white24),
            
            // Advanced settings
            _buildAdvancedSettings(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tag,
                color: Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tags',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_tags.length}/5',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tag input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  enabled: _tags.length < 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add tags to help people discover your video',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _tags.length < 5 ? _addTag : null,
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          // Tag chips
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.cardColor,
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white60,
                  ),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildThumbnailSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image,
                color: Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Select Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Thumbnail options
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Mock thumbnails
              itemBuilder: (context, index) {
                final isSelected = _selectedThumbnailIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedThumbnailIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Who can view this video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Visibility options
          _buildRadioOption(
            value: 'public',
            groupValue: _visibility,
            label: 'Everyone',
            subtitle: 'Anyone can view this video',
            onChanged: (value) {
              setState(() {
                _visibility = value!;
              });
            },
          ),
          _buildRadioOption(
            value: 'friends',
            groupValue: _visibility,
            label: 'Friends',
            subtitle: 'Only your friends can view this video',
            onChanged: (value) {
              setState(() {
                _visibility = value!;
              });
            },
          ),
          _buildRadioOption(
            value: 'private',
            groupValue: _visibility,
            label: 'Only me',
            subtitle: 'Only you can view this video',
            onChanged: (value) {
              setState(() {
                _visibility = value!;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Advanced Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildSwitchOption(
            title: 'Allow comments',
            subtitle: 'People can comment on your video',
            value: _allowComments,
            onChanged: (value) {
              setState(() {
                _allowComments = value;
              });
            },
          ),
          _buildSwitchOption(
            title: 'Allow duet',
            subtitle: 'People can create duets with your video',
            value: _allowDuet,
            onChanged: (value) {
              setState(() {
                _allowDuet = value;
              });
            },
          ),
          _buildSwitchOption(
            title: 'Allow stitch',
            subtitle: 'People can use parts of your video',
            value: _allowStitch,
            onChanged: (value) {
              setState(() {
                _allowStitch = value;
              });
            },
          ),
          _buildSwitchOption(
            title: 'Allow download',
            subtitle: 'People can save your video',
            value: _allowDownload,
            onChanged: (value) {
              setState(() {
                _allowDownload = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRadioOption<T>({
    required T value,
    required T groupValue,
    required String label,
    required String subtitle,
    required Function(T?) onChanged,
  }) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}