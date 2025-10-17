import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/feed_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/post_model.dart';
import '../widgets/tiktok_feed_item.dart';
import '../../../app/theme/app_theme.dart';

class TikTokStyleFeed extends StatefulWidget {
  const TikTokStyleFeed({Key? key}) : super(key: key);

  @override
  State<TikTokStyleFeed> createState() => _TikTokStyleFeedState();
}

class _TikTokStyleFeedState extends State<TikTokStyleFeed> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isForYouSelected = true;
  
  // Animation controllers for smooth transitions
  late AnimationController _tabAnimationController;
  late AnimationController _fadeAnimationController;
  
  // Preloading management
  final Set<int> _preloadedIndices = {};
  static const int _preloadRadius = 2; // Preload 2 videos ahead and behind
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
      _preloadVideos();
    });
  }
  
  @override
  void dispose() {
    _tabAnimationController.dispose();
    _fadeAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _loadFeed() {
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    
    if (_isForYouSelected) {
      feedService.loadForYouFeed(userId: authService.currentUser?.id);
    } else {
      feedService.loadReelsFeed();
    }
  }
  
  void _preloadVideos() {
    final feedService = context.read<FeedService>();
    final posts = _isForYouSelected ? feedService.forYouFeed : feedService.reelsFeed;
    
    // Preload videos within radius
    for (int i = _currentIndex - _preloadRadius; i <= _currentIndex + _preloadRadius; i++) {
      if (i >= 0 && i < posts.length && !_preloadedIndices.contains(i)) {
        _preloadedIndices.add(i);
        // Trigger preload logic here
      }
    }
  }
  
  void _onPageChanged(int index) {
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    final posts = _isForYouSelected ? feedService.forYouFeed : feedService.reelsFeed;
    
    // Analytics tracking
    if (_currentIndex < posts.length) {
      feedService.stopVideoView(posts[_currentIndex].id);
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    if (index < posts.length) {
      feedService.trackVideoView(
        posts[index].id,
        userId: authService.currentUser?.id,
      );
    }
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
    
    // Preload more videos
    _preloadVideos();
    
    // Load more content if approaching end
    if (index >= posts.length - 5) {
      _loadFeed();
    }
  }
  
  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    final feedService = context.read<FeedService>();
    final authService = context.read<AuthService>();
    
    await _fadeAnimationController.reverse();
    
    if (_isForYouSelected) {
      await feedService.loadForYouFeed(
        refresh: true,
        userId: authService.currentUser?.id,
      );
    } else {
      await feedService.loadReelsFeed(refresh: true);
    }
    
    await _fadeAnimationController.forward();
  }
  
  void _switchTab(bool toForYou) {
    if (_isForYouSelected != toForYou) {
      HapticFeedback.lightImpact();
      setState(() {
        _isForYouSelected = toForYou;
        _currentIndex = 0;
        _preloadedIndices.clear();
      });
      _tabAnimationController.forward().then((_) {
        _tabAnimationController.reverse();
      });
      _loadFeed();
      _pageController.jumpToPage(0);
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
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video feed
          AnimatedBuilder(
            animation: _fadeAnimationController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimationController.value,
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primaryColor,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return TikTokFeedItem(
                      post: post,
                      isActive: index == _currentIndex,
                      preload: _preloadedIndices.contains(index),
                      onLike: () {
                        final authService = context.read<AuthService>();
                        feedService.likePost(
                          post.id,
                          userId: authService.currentUser?.id,
                        );
                      },
                      onComment: () {
                        _showCommentsSheet(post);
                      },
                      onShare: () {
                        _showShareSheet(post);
                      },
                      onFollow: () {
                        // Implement follow functionality
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Top navigation bar
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Live streaming button (optional)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  // Navigate to live streaming
                },
                icon: const Icon(
                  Icons.live_tv_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // For You / Following toggle
          ScaleTransition(
            scale: Tween<double>(
              begin: 1.0,
              end: 0.95,
            ).animate(_tabAnimationController),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _switchTab(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Following',
                          style: TextStyle(
                            color: !_isForYouSelected ? Colors.white : Colors.white60,
                            fontSize: 17,
                            fontWeight: !_isForYouSelected ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: !_isForYouSelected ? 0.5 : 0,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(top: 4),
                          width: !_isForYouSelected ? 30 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                
                GestureDetector(
                  onTap: () => _switchTab(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'For You',
                          style: TextStyle(
                            color: _isForYouSelected ? Colors.white : Colors.white60,
                            fontSize: 17,
                            fontWeight: _isForYouSelected ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: _isForYouSelected ? 0.5 : 0,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(top: 4),
                          width: _isForYouSelected ? 30 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search button
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  // Navigate to search
                },
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCommentsSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${post.commentsCount} comments',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: const [
                    Center(child: Text('Comments coming soon')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showShareSheet(Post post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Share options row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildShareOption(Icons.message, 'Messages'),
                    _buildShareOption(Icons.facebook, 'Facebook'),
                    _buildShareOption(Icons.share, 'Twitter'),
                    _buildShareOption(Icons.link, 'Copy Link'),
                    _buildShareOption(Icons.more_horiz, 'More'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.grey, height: 1),
              
              // Additional options
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: const Text('Report', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined, color: Colors.white),
                title: const Text('Save video', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.not_interested_outlined, color: Colors.white),
                title: const Text('Not interested', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildShareOption(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
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
}