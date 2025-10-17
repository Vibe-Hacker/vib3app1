import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../app/theme/app_theme.dart';

class CameraEffectOverlay extends StatefulWidget {
  final String effect;
  
  const CameraEffectOverlay({
    Key? key,
    required this.effect,
  }) : super(key: key);
  
  @override
  State<CameraEffectOverlay> createState() => _CameraEffectOverlayState();
}

class _CameraEffectOverlayState extends State<CameraEffectOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: _getEffectOverlay(),
      ),
    );
  }
  
  Widget _getEffectOverlay() {
    switch (widget.effect) {
      case 'blur':
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.transparent),
        );
        
      case 'zoom_blur':
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_animationController.value * 0.1),
              child: Opacity(
                opacity: 1 - _animationController.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        
      case 'glitch':
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    (_animationController.value * 10) - 5,
                    0,
                  ),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.red,
                      BlendMode.screen,
                    ),
                    child: Container(),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -(_animationController.value * 10) + 5,
                    0,
                  ),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.blue,
                      BlendMode.screen,
                    ),
                    child: Container(),
                  ),
                );
              },
            ),
          ],
        );
        
      case 'rgb_split':
        return Stack(
          children: [
            Transform.translate(
              offset: const Offset(-2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.red,
                  BlendMode.screen,
                ),
                child: Container(),
              ),
            ),
            Transform.translate(
              offset: const Offset(2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.blue,
                  BlendMode.screen,
                ),
                child: Container(),
              ),
            ),
          ],
        );
        
      case 'particle':
        return _ParticleOverlay(controller: _animationController);
        
      default:
        return Container();
    }
  }
}

class _ParticleOverlay extends StatelessWidget {
  final AnimationController controller;
  
  const _ParticleOverlay({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(20, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final progress = (controller.value + index / 20) % 1.0;
            return Positioned(
              left: MediaQuery.of(context).size.width * (index / 20),
              top: MediaQuery.of(context).size.height * progress,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class EffectSelectionSheet extends StatelessWidget {
  final String? selectedEffect;
  final Function(String?) onEffectSelected;
  
  const EffectSelectionSheet({
    Key? key,
    required this.selectedEffect,
    required this.onEffectSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effects = [
      EffectOption(id: null, name: 'None', icon: Icons.clear),
      EffectOption(id: 'blur', name: 'Blur', icon: Icons.blur_on),
      EffectOption(id: 'zoom_blur', name: 'Zoom', icon: Icons.zoom_out_map),
      EffectOption(id: 'glitch', name: 'Glitch', icon: Icons.broken_image),
      EffectOption(id: 'rgb_split', name: 'RGB', icon: Icons.gradient),
      EffectOption(id: 'mirror', name: 'Mirror', icon: Icons.flip),
      EffectOption(id: 'kaleidoscope', name: 'Kaleido', icon: Icons.star),
      EffectOption(id: 'particle', name: 'Sparkle', icon: Icons.auto_awesome),
    ];
    
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Effects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: effects.length,
              itemBuilder: (context, index) {
                final effect = effects[index];
                final isSelected = selectedEffect == effect.id;
                
                return GestureDetector(
                  onTap: () => onEffectSelected(effect.id),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
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
                          effect.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ).animate(
                        target: isSelected ? 1 : 0,
                      ).scaleXY(
                        begin: 1.0,
                        end: 1.1,
                        duration: 200.ms,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effect.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EffectOption {
  final String? id;
  final String name;
  final IconData icon;
  
  EffectOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}