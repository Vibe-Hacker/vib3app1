import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';

class MusicPicker extends StatefulWidget {
  final Function(MusicTrack) onMusicSelected;
  final VoidCallback onClose;
  
  const MusicPicker({
    Key? key,
    required this.onMusicSelected,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<MusicPicker> createState() => _MusicPickerState();
}

class _MusicPickerState extends State<MusicPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Mock music data - in production, this would come from an API
  final Map<String, List<MusicTrack>> _musicCategories = {
    'Trending': [
      MusicTrack(
        id: '1',
        title: 'Summer Vibes',
        artist: 'DJ Sunshine',
        duration: const Duration(seconds: 30),
        thumbnailUrl: '',
        audioUrl: '',
      ),
      MusicTrack(
        id: '2',
        title: 'Dance Party',
        artist: 'Beat Master',
        duration: const Duration(seconds: 28),
        thumbnailUrl: '',
        audioUrl: '',
      ),
      MusicTrack(
        id: '3',
        title: 'Chill Beats',
        artist: 'Lo-Fi Producer',
        duration: const Duration(seconds: 32),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'For You': [
      MusicTrack(
        id: '4',
        title: 'Hip Hop Flow',
        artist: 'MC Fresh',
        duration: const Duration(seconds: 25),
        thumbnailUrl: '',
        audioUrl: '',
      ),
      MusicTrack(
        id: '5',
        title: 'Electronic Dream',
        artist: 'Synth Wave',
        duration: const Duration(seconds: 30),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'Pop': [
      MusicTrack(
        id: '6',
        title: 'Pop Sensation',
        artist: 'Star Singer',
        duration: const Duration(seconds: 29),
        thumbnailUrl: '',
        audioUrl: '',
      ),
      MusicTrack(
        id: '7',
        title: 'Feel Good',
        artist: 'Happy Band',
        duration: const Duration(seconds: 31),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'Hip Hop': [
      MusicTrack(
        id: '8',
        title: 'Street Anthem',
        artist: 'Urban Legend',
        duration: const Duration(seconds: 27),
        thumbnailUrl: '',
        audioUrl: '',
      ),
      MusicTrack(
        id: '9',
        title: 'Rap Battle',
        artist: 'Lyrical Genius',
        duration: const Duration(seconds: 30),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'Rock': [
      MusicTrack(
        id: '10',
        title: 'Rock Anthem',
        artist: 'Guitar Heroes',
        duration: const Duration(seconds: 33),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'Electronic': [
      MusicTrack(
        id: '11',
        title: 'EDM Drop',
        artist: 'Bass Master',
        duration: const Duration(seconds: 28),
        thumbnailUrl: '',
        audioUrl: '',
      ),
    ],
    'Saved': [],
  };
  
  String? _playingTrackId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _musicCategories.length,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Sound',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search sounds',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.white60,
              tabs: _musicCategories.keys.map((category) {
                return Tab(text: category);
              }).toList(),
            ),
            
            // Music list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _musicCategories.entries.map((entry) {
                  return _buildMusicList(entry.value);
                }).toList(),
              ),
            ),
          ],
        ),
      ).animate().slideY(
        begin: 1,
        end: 0,
        duration: 300.ms,
        curve: Curves.easeOut,
      ),
    );
  }
  
  Widget _buildMusicList(List<MusicTrack> tracks) {
    final filteredTracks = _searchQuery.isEmpty
        ? tracks
        : tracks.where((track) {
            return track.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   track.artist.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    
    if (filteredTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No sounds available'
                  : 'No sounds found',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredTracks.length,
      itemBuilder: (context, index) {
        final track = filteredTracks[index];
        final isPlaying = _playingTrackId == track.id;
        
        return _buildMusicTile(track, isPlaying, index);
      },
    );
  }
  
  Widget _buildMusicTile(MusicTrack track, bool isPlaying, int index) {
    return InkWell(
      onTap: () => widget.onMusicSelected(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Thumbnail/Play button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
                image: track.thumbnailUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(track.thumbnailUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isPlaying) {
                        _playingTrackId = null;
                      } else {
                        _playingTrackId = track.id;
                      }
                    });
                    // TODO: Actually play/pause the audio
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        track.artist,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_formatDuration(track.duration)}',
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
            
            // Action buttons
            IconButton(
              onPressed: () {
                // TODO: Add to favorites
              },
              icon: Icon(
                Icons.favorite_border,
                color: Colors.white60,
              ),
            ),
            
            // Use button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Use',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
        delay: (index * 50).ms,
        duration: 300.ms,
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String thumbnailUrl;
  final String audioUrl;
  
  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnailUrl,
    required this.audioUrl,
  });
}