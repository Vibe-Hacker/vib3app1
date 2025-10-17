import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/post_model.dart';
import '../../../core/utils/number_formatter.dart';
import '../../video_player/widgets/vib3_video_player.dart';

class TikTokFeedItem extends StatefulWidget {
  final Post post;
  final bool isActive;
  final bool preload;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;
  
  const TikTokFeedItem({
    Key? key,
    required this.post,
    required this.isActive,
    this.preload = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onFollow,
  }) : super(key: key);
  
  @override
  State<TikTokFeedItem> createState() => _TikTokFeedItemState();
}

class _TikTokFeedItemState extends State<TikTokFeedItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  bool _isLiked = false;
  bool _showMoreCaption = false;
  
  // Animation values
  final List<Offset> _doubleTapPositions = [];
  
  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.easeOut,
    ));
    
    _isLiked = widget.post.isLiked;
  }
  
  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }
  
  void _handleDoubleTap(TapDownDetails details) {
    if (!_isLiked) {
      _handleLike();
    }
    
    // Add tap position for heart animation
    setState(() {
      _doubleTapPositions.add(details.localPosition);
    });
    
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reset();
      setState(() {
        _doubleTapPositions.clear();
      });
    });
  }
  
  void _handleLike() {
    setState(() => _isLiked = !_isLiked);
    HapticFeedback.lightImpact();
    widget.onLike?.call();
  }
  
  void _handleFollow() {
    HapticFeedback.lightImpact();
    widget.onFollow?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    // For web, use a centered layout with max width
    if (kIsWeb) {
      return Container(
        color: Colors.black,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // Mobile-like width
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-screen video background
                _buildVideoContent(),

                // Gradient overlay for better text visibility
                _buildGradientOverlay(),

                // Main content
                _buildMainContent(),

                // Right side actions
                _buildSideActions(),

                // Double tap heart animations
                ..._buildHeartAnimations(),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout - original full screen
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen video background
        _buildVideoContent(),

        // Gradient overlay for better text visibility
        _buildGradientOverlay(),

        // Main content
        _buildMainContent(),

        // Right side actions
        _buildSideActions(),

        // Double tap heart animations
        ..._buildHeartAnimations(),
      ],
    );
  }
  
  Widget _buildVideoContent() {
    if (widget.post.media.isEmpty) {
      return Container(color: Colors.black);
    }
    
    final media = widget.post.media.first;
    
    if (media.type == MediaType.video) {
      return GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: VIB3VideoPlayer(
          videoUrl: media.url,
          isPlaying: widget.isActive,
          thumbnailUrl: media.thumbnailUrl,
          showControls: false,
          preload: widget.preload || widget.isActive,
        ),
      );
    }
    
    // Image fallback
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTap,
      child: CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.5),
            ],
            stops: const [0.0, 0.6, 0.9, 1.0],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainContent() {
    return Positioned(
      left: kIsWeb ? 16 : 12,
      right: kIsWeb ? 100 : 100, // Keep space for action buttons
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Author info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to profile
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.post.author?.profilePicture ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.person, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '@${widget.post.author?.username ?? 'unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (widget.post.userId != 'current_user_id') ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _handleFollow,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Follow',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.post.author?.displayName != null)
                      Text(
                        widget.post.author!.displayName!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Caption with expand/collapse
          if (widget.post.caption != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMoreCaption = !_showMoreCaption;
                });
              },
              child: Text(
                widget.post.caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: _showMoreCaption ? null : 2,
                overflow: _showMoreCaption ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Tags/Hashtags
          if (widget.post.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.post.tags.map((tag) => Text(
                '#$tag',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              )).toList(),
            ),
          
          const SizedBox(height: 8),
          
          // Sound info
          if (widget.post.sound != null)
            GestureDetector(
              onTap: () {
                // Navigate to sound page
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${widget.post.sound!.name} - ${widget.post.sound!.artistName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).shimmer(
                      duration: const Duration(seconds: 3),
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSideActions() {
    return Positioned(
      right: kIsWeb ? 12 : 10, // Slightly adjust for web
      bottom: 60,
      child: Column(
        children: [
          // Profile picture with follow button
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to profile
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.post.author?.profilePicture ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.post.userId != 'current_user_id')
                Transform.translate(
                  offset: const Offset(0, 8),
                  child: GestureDetector(
                    onTap: _handleFollow,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Like button
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            label: NumberFormatter.format(widget.post.likesCount + (_isLiked ? 1 : 0)),
            onTap: _handleLike,
            size: 40,
          ),
          
          const SizedBox(height: 18),
          
          // Comment button
          _buildActionButton(
            icon: Icons.mode_comment,
            label: NumberFormatter.format(widget.post.commentsCount),
            onTap: widget.onComment,
            size: 36,
          ),
          
          const SizedBox(height: 18),
          
          // Bookmark button
          _buildActionButton(
            icon: widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: widget.post.isSaved ? 'Saved' : 'Save',
            onTap: () {
              // Handle bookmark
            },
            size: 36,
          ),
          
          const SizedBox(height: 18),
          
          // Share button
          _buildActionButton(
            icon: Icons.send,
            label: NumberFormatter.format(widget.post.sharesCount),
            onTap: widget.onShare,
            size: 36,
          ),
          
          const SizedBox(height: 18),
          
          // Sound disc (if available)
          if (widget.post.sound != null)
            GestureDetector(
              onTap: () {
                // Navigate to sound page
              },
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.grey[900]!,
                      Colors.black,
                    ],
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.post.sound!.albumArt ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).rotate(
                duration: const Duration(seconds: 5),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    String? label,
    Color color = Colors.white,
    VoidCallback? onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        // Add a small scale animation
        HapticFeedback.lightImpact();
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: size,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ).animate(target: 0)
          .scale(duration: const Duration(milliseconds: 100)),
    );
  }
  
  List<Widget> _buildHeartAnimations() {
    return _doubleTapPositions.map((position) {
      return Positioned(
        left: position.dx - 40,
        top: position.dy - 80,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -100 * _heartAnimation.value),
                child: Opacity(
                  opacity: 1 - _heartAnimation.value,
                  child: Transform.scale(
                    scale: 0.8 + (_heartAnimation.value * 0.4),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 80,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }
}