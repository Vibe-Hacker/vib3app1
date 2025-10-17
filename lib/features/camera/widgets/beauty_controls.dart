import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_theme.dart';

class BeautyControlPanel extends StatefulWidget {
  final double beautyLevel;
  final Function(double) onBeautyChanged;
  final VoidCallback onClose;
  
  const BeautyControlPanel({
    Key? key,
    required this.beautyLevel,
    required this.onBeautyChanged,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<BeautyControlPanel> createState() => _BeautyControlPanelState();
}

class _BeautyControlPanelState extends State<BeautyControlPanel> {
  late double _smoothLevel;
  late double _brightenLevel;
  late double _slimLevel;
  late double _eyeEnlargeLevel;
  
  @override
  void initState() {
    super.initState();
    _smoothLevel = widget.beautyLevel;
    _brightenLevel = widget.beautyLevel * 0.8;
    _slimLevel = widget.beautyLevel * 0.5;
    _eyeEnlargeLevel = widget.beautyLevel * 0.3;
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Beauty',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Reset button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _smoothLevel = 0;
                          _brightenLevel = 0;
                          _slimLevel = 0;
                          _eyeEnlargeLevel = 0;
                        });
                        widget.onBeautyChanged(0);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    // Close button
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Presets
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPreset('Natural', 0.3, Icons.eco),
                  _buildPreset('Soft', 0.5, Icons.blur_on),
                  _buildPreset('Glamour', 0.7, Icons.auto_awesome),
                  _buildPreset('Max', 1.0, Icons.star),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Smooth skin
            _buildSlider(
              label: 'Smooth',
              icon: Icons.face,
              value: _smoothLevel,
              onChanged: (value) {
                setState(() {
                  _smoothLevel = value;
                });
                _updateOverallBeauty();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Brighten
            _buildSlider(
              label: 'Brighten',
              icon: Icons.brightness_6,
              value: _brightenLevel,
              onChanged: (value) {
                setState(() {
                  _brightenLevel = value;
                });
                _updateOverallBeauty();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Slim face
            _buildSlider(
              label: 'Slim Face',
              icon: Icons.face_retouching_natural,
              value: _slimLevel,
              onChanged: (value) {
                setState(() {
                  _slimLevel = value;
                });
                _updateOverallBeauty();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Eye enlarge
            _buildSlider(
              label: 'Eye Enlarge',
              icon: Icons.visibility,
              value: _eyeEnlargeLevel,
              onChanged: (value) {
                setState(() {
                  _eyeEnlargeLevel = value;
                });
                _updateOverallBeauty();
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
    );
  }
  
  Widget _buildPreset(String label, double level, IconData icon) {
    final isSelected = (widget.beautyLevel - level).abs() < 0.05;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _smoothLevel = level;
            _brightenLevel = level * 0.8;
            _slimLevel = level * 0.5;
            _eyeEnlargeLevel = level * 0.3;
          });
          widget.onBeautyChanged(level);
        },
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white24,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required Function(double) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  void _updateOverallBeauty() {
    final overall = (_smoothLevel + _brightenLevel + _slimLevel + _eyeEnlargeLevel) / 4;
    widget.onBeautyChanged(overall);
  }
}