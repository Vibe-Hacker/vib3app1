import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';

class TextOverlayEditor extends StatefulWidget {
  final Function(String, TextStyle) onSave;
  final VoidCallback onCancel;
  
  const TextOverlayEditor({
    Key? key,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  State<TextOverlayEditor> createState() => _TextOverlayEditorState();
}

class _TextOverlayEditorState extends State<TextOverlayEditor> {
  final TextEditingController _textController = TextEditingController();
  
  // Text style options
  Color _textColor = Colors.white;
  double _fontSize = 24;
  FontWeight _fontWeight = FontWeight.normal;
  TextAlign _textAlign = TextAlign.center;
  bool _hasBackground = false;
  Color _backgroundColor = Colors.black;
  
  // Font options
  final List<String> _fonts = [
    'Default',
    'Bold',
    'Italic',
    'Outline',
    'Shadow',
    'Neon',
  ];
  String _selectedFont = 'Default';
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Text input area
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasBackground
                          ? _backgroundColor.withOpacity(0.8)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      textAlign: _textAlign,
                      style: _getTextStyle(),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type your text...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Style options
              _buildStyleOptions(),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Text(
            'Add Text',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                widget.onSave(_textController.text, _getTextStyle());
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStyleOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font styles
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fonts.length,
              itemBuilder: (context, index) {
                final font = _fonts[index];
                final isSelected = _selectedFont == font;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFont = font;
                        _updateFontStyle();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        font,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Color and style options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Text color
              _buildColorOption(
                icon: Icons.format_color_text,
                color: _textColor,
                onTap: () => _showColorPicker(true),
              ),
              
              // Background toggle
              _buildToggleOption(
                icon: Icons.format_color_fill,
                isActive: _hasBackground,
                onTap: () {
                  setState(() {
                    _hasBackground = !_hasBackground;
                  });
                },
              ),
              
              // Background color
              if (_hasBackground)
                _buildColorOption(
                  icon: Icons.color_lens,
                  color: _backgroundColor,
                  onTap: () => _showColorPicker(false),
                ),
              
              // Alignment
              _buildAlignmentOption(),
              
              // Font size
              _buildFontSizeOption(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorOption({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildToggleOption({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.white24,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildAlignmentOption() {
    final alignments = [
      TextAlign.left,
      TextAlign.center,
      TextAlign.right,
    ];
    
    return PopupMenuButton<TextAlign>(
      initialValue: _textAlign,
      onSelected: (align) {
        setState(() {
          _textAlign = align;
        });
      },
      itemBuilder: (context) => alignments.map((align) {
        return PopupMenuItem(
          value: align,
          child: Icon(
            align == TextAlign.left
                ? Icons.format_align_left
                : align == TextAlign.center
                    ? Icons.format_align_center
                    : Icons.format_align_right,
          ),
        );
      }).toList(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white24,
            width: 2,
          ),
        ),
        child: Icon(
          _textAlign == TextAlign.left
              ? Icons.format_align_left
              : _textAlign == TextAlign.center
                  ? Icons.format_align_center
                  : Icons.format_align_right,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildFontSizeOption() {
    return GestureDetector(
      onTap: _showFontSizeSlider,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white24,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.text_fields,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  TextStyle _getTextStyle() {
    TextStyle style = TextStyle(
      color: _textColor,
      fontSize: _fontSize,
      fontWeight: _fontWeight,
    );
    
    // Apply font styles
    switch (_selectedFont) {
      case 'Bold':
        style = style.copyWith(fontWeight: FontWeight.bold);
        break;
      case 'Italic':
        style = style.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'Outline':
        // This would need custom painting in actual implementation
        style = style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _textColor,
        );
        break;
      case 'Shadow':
        style = style.copyWith(
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        );
        break;
      case 'Neon':
        style = style.copyWith(
          shadows: [
            Shadow(
              color: _textColor,
              blurRadius: 10,
            ),
            Shadow(
              color: _textColor,
              blurRadius: 20,
            ),
          ],
        );
        break;
    }
    
    return style;
  }
  
  void _updateFontStyle() {
    // Update font style based on selection
  }
  
  void _showColorPicker(bool isTextColor) {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isTextColor) {
                    _textColor = color;
                  } else {
                    _backgroundColor = color;
                  }
                });
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  void _showFontSizeSlider() {
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
            const Text(
              'Text Size',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _fontSize,
              min: 12,
              max: 72,
              activeColor: AppTheme.primaryColor,
              inactiveColor: Colors.white24,
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            Text(
              _fontSize.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying text overlay
class TextOverlayWidget extends StatefulWidget {
  final TextOverlay overlay;
  final Function(TextOverlay) onUpdate;
  final VoidCallback onDelete;
  
  const TextOverlayWidget({
    Key? key,
    required this.overlay,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  State<TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<TextOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.overlay.position.dx * MediaQuery.of(context).size.width - 100,
      top: widget.overlay.position.dy * MediaQuery.of(context).size.height - 50,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            widget.overlay.position = Offset(
              (widget.overlay.position.dx + details.delta.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0),
              (widget.overlay.position.dy + details.delta.dy / MediaQuery.of(context).size.height).clamp(0.0, 1.0),
            );
          });
          widget.onUpdate(widget.overlay);
        },
        onLongPress: widget.onDelete,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            widget.overlay.text,
            style: widget.overlay.style,
          ),
        ),
      ),
    );
  }
}

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