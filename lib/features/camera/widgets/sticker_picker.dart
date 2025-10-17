import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';
import '../screens/video_edit_screen.dart';

class StickerPicker extends StatefulWidget {
  final Function(String) onStickerSelected;
  final VoidCallback onClose;
  
  const StickerPicker({
    Key? key,
    required this.onStickerSelected,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<String, List<String>> _stickerCategories = {
    'Trending': ['🔥', '💯', '✨', '👑', '🎉', '🎯', '💪', '🚀', '⚡', '🌟'],
    'Emotions': ['😂', '🥰', '😎', '🤔', '😱', '🥺', '😭', '🤯', '😍', '🙄'],
    'Love': ['❤️', '💕', '💖', '💗', '💝', '💘', '💞', '😘', '🥰', '💑'],
    'Fun': ['🎈', '🎊', '🎁', '🎪', '🎨', '🎭', '🎮', '🎯', '🎰', '🎲'],
    'Food': ['🍕', '🍔', '🍟', '🌮', '🍿', '🍩', '🍰', '🍦', '🍺', '☕'],
    'Animals': ['🐶', '🐱', '🐻', '🐼', '🐨', '🦄', '🦋', '🐝', '🦁', '🐙'],
    'Nature': ['🌈', '☀️', '⭐', '🌙', '☁️', '⚡', '❄️', '🌊', '🌺', '🌸'],
    'Sports': ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓', '🥊', '🎯', '🏆'],
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _stickerCategories.length,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                    'Stickers',
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
            
            // Category tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.white60,
              tabs: _stickerCategories.keys.map((category) {
                return Tab(text: category);
              }).toList(),
            ),
            
            // Sticker grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _stickerCategories.entries.map((entry) {
                  return _buildStickerGrid(entry.value);
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
  
  Widget _buildStickerGrid(List<String> stickers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: () => widget.onStickerSelected(sticker),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white12,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                sticker,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ).animate().scaleXY(
            delay: (index * 50).ms,
            duration: 300.ms,
            begin: 0.8,
            end: 1.0,
            curve: Curves.easeOut,
          ),
        );
      },
    );
  }
}

// Widget for displaying sticker overlay
class StickerWidget extends StatefulWidget {
  final StickerOverlay sticker;
  final Function(StickerOverlay) onUpdate;
  final VoidCallback onDelete;
  
  const StickerWidget({
    Key? key,
    required this.sticker,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  State<StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<StickerWidget> {
  late Offset _position;
  late double _scale;
  late double _rotation;
  Offset? _initialFocalPoint;
  Offset? _initialPosition;
  double? _initialScale;
  double? _initialRotation;
  
  @override
  void initState() {
    super.initState();
    _position = widget.sticker.position;
    _scale = widget.sticker.scale;
    _rotation = widget.sticker.rotation;
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Positioned(
      left: _position.dx * size.width - 40,
      top: _position.dy * size.height - 40,
      child: GestureDetector(
        onScaleStart: (details) {
          _initialFocalPoint = details.focalPoint;
          _initialPosition = _position;
          _initialScale = _scale;
          _initialRotation = _rotation;
        },
        onScaleUpdate: (details) {
          if (_initialFocalPoint == null) return;
          
          setState(() {
            // Update position
            final delta = details.focalPoint - _initialFocalPoint!;
            _position = Offset(
              (_initialPosition!.dx + delta.dx / size.width).clamp(0.0, 1.0),
              (_initialPosition!.dy + delta.dy / size.height).clamp(0.0, 1.0),
            );
            
            // Update scale
            _scale = (_initialScale! * details.scale).clamp(0.5, 3.0);
            
            // Update rotation
            _rotation = _initialRotation! + details.rotation;
          });
          
          widget.sticker.position = _position;
          widget.sticker.scale = _scale;
          widget.sticker.rotation = _rotation;
          widget.onUpdate(widget.sticker);
        },
        onLongPress: widget.onDelete,
        child: Transform.rotate(
          angle: _rotation,
          child: Transform.scale(
            scale: _scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  widget.sticker.sticker,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}