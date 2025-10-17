import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class FeedStyleDemoScreen extends StatelessWidget {
  const FeedStyleDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Choose Your Feed Style'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your Preferred\nVideo Feed Experience',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Instagram Reels Style
              _buildFeedOption(
                context,
                title: 'Instagram Style',
                subtitle: 'Rounded corners, familiar layout',
                features: [
                  'Rounded video corners',
                  'Tab navigation at top',
                  'Traditional action buttons',
                  'Compact user interface',
                ],
                gradientColors: [
                  const Color(0xFFE1306C),
                  const Color(0xFFF56040),
                  const Color(0xFFFCAF45),
                ],
                onTap: () => context.push('/reels'),
              ),
              
              const SizedBox(height: 24),
              
              // TikTok Style
              _buildFeedOption(
                context,
                title: 'TikTok Style',
                subtitle: 'Full-screen immersive experience',
                features: [
                  'Edge-to-edge videos',
                  'Minimal top navigation',
                  'Large action buttons',
                  'Immersive viewing',
                ],
                gradientColors: [
                  const Color(0xFF000000),
                  const Color(0xFFFF0050),
                  const Color(0xFF00F2EA),
                ],
                onTap: () => context.push('/tiktok-feed'),
              ),
              
              const SizedBox(height: 48),
              
              // Info text
              Text(
                'You can switch between styles anytime in Settings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeedOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> features,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Try Now',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}