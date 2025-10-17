import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/feed_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/post_model.dart';
import '../../feed/widgets/video_feed_item.dart';
import '../../../app/theme/app_theme.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isForYouSelected = true; // Default to For You page
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Load appropriate feed when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }
  
  void _loadFeed() {
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    
    if (_isForYouSelected) {
      // Load personalized For You feed
      feedService.loadForYouFeed(
        userId: authService.currentUser?.id,
      );
    } else {
      // Load regular reels feed
      feedService.loadReelsFeed();
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    final posts = _isForYouSelected ? feedService.forYouFeed : feedService.reelsFeed;
    
    // Stop tracking previous video
    if (_currentIndex < posts.length) {
      feedService.stopVideoView(posts[_currentIndex].id);
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // Start tracking new video
    if (index < posts.length) {
      feedService.trackVideoView(
        posts[index].id,
        userId: authService.currentUser?.id,
      );
    }
    
    HapticFeedback.lightImpact();
    
    // Load more content if approaching end
    if (index >= posts.length - 3) {
      _loadFeed();
    }
  }
  
  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    
    if (_isForYouSelected) {
      await feedService.loadForYouFeed(
        refresh: true,
        userId: authService.currentUser?.id,
      );
    } else {
      await feedService.loadReelsFeed(refresh: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feedService = context.watch<FeedService>();
    final posts = _isForYouSelected ? feedService.forYouFeed : feedService.reelsFeed;
    
    if (posts.isEmpty && feedService.isLoadingReels) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Feed
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return VideoFeedItem(
                  post: post,
                  isActive: index == _currentIndex,
                  onLike: () {
                    final authService = context.read<AuthService>();
                    feedService.likePost(
                      post.id,
                      userId: authService.currentUser?.id,
                    );
                  },
                  onComment: () {
                    final authService = context.read<AuthService>();
                    feedService.trackComment(
                      post.id,
                      userId: authService.currentUser?.id,
                    );
                    _showCommentsSheet(post);
                  },
                  onShare: () {
                    final authService = context.read<AuthService>();
                    feedService.trackShare(
                      post.id,
                      userId: authService.currentUser?.id,
                    );
                    _showShareOptions(post);
                  },
                  onFollow: () {
                    // TODO: Implement follow functionality
                  },
                );
              },
            ),
          ),
          
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildTopBar(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live button
          IconButton(
            onPressed: () {
              // TODO: Navigate to live streaming
            },
            icon: const Icon(
              Icons.live_tv_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          // For You / Following Toggle
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!_isForYouSelected) {
                    setState(() {
                      _isForYouSelected = true;
                    });
                    _loadFeed();
                  }
                },
                child: Column(
                  children: [
                    Text(
                      'For You',
                      style: TextStyle(
                        color: _isForYouSelected ? Colors.white : Colors.white60,
                        fontSize: 16,
                        fontWeight: _isForYouSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (_isForYouSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  if (_isForYouSelected) {
                    setState(() {
                      _isForYouSelected = false;
                    });
                    _loadFeed();
                  }
                },
                child: Column(
                  children: [
                    Text(
                      'Following',
                      style: TextStyle(
                        color: !_isForYouSelected ? Colors.white : Colors.white60,
                        fontSize: 16,
                        fontWeight: !_isForYouSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (!_isForYouSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 50,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Search button
          IconButton(
            onPressed: () {
              // TODO: Navigate to search
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          // Following | For You tabs
          Row(
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Switch to following feed
                },
                child: Text(
                  'Following',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 20,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  // Already on For You
                },
                child: const Text(
                  'For You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Search button
          IconButton(
            onPressed: () {
              // TODO: Navigate to search
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCommentsSheet(Post reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Comments header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${reel.commentsCount} comments',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // TODO: Add comments list
            const Expanded(
              child: Center(
                child: Text('Comments coming soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showShareOptions(Post reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share to...'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Copy link
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Save video'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Save video
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}