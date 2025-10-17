# VIB3 Project Structure

## Overview
This document outlines the modular structure of the VIB3 app to ensure maintainability and prevent breaking changes when working on different features.

## Directory Structure

```
lib/
├── app/                          # App-wide configuration
│   ├── routes/                   # Navigation and routing
│   │   └── app_router.dart       # GoRouter configuration
│   └── theme/                    # App theming
│       └── app_theme.dart        # Colors, styles, gradients
│
├── core/                         # Core functionality shared across features
│   ├── api/                      # API client implementations
│   ├── config/                   # Configuration files
│   │   └── api_config.dart       # API endpoints and settings
│   ├── models/                   # Data models
│   │   ├── user_model.dart       # User data structure
│   │   ├── post_model.dart       # Post, Comment, Sound models
│   │   ├── story_model.dart      # Story data structure
│   │   └── message_model.dart    # Message data structure
│   ├── services/                 # Business logic services
│   │   ├── api_service.dart      # HTTP client wrapper
│   │   ├── auth_service.dart     # Authentication logic
│   │   ├── storage_service.dart  # Local storage (Hive)
│   │   ├── feed_service.dart     # Feed data management
│   │   ├── post_service.dart     # Post CRUD operations
│   │   ├── recommendation_engine.dart    # AI recommendation system
│   │   └── interaction_tracking_service.dart  # User behavior tracking
│   ├── utils/                    # Utility functions
│   └── widgets/                  # Reusable widgets
│
├── features/                     # Feature modules (isolated functionality)
│   ├── auth/                     # Authentication feature
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── onboarding_screen.dart
│   │       ├── login_screen.dart
│   │       └── signup_screen.dart
│   │
│   ├── feed/                     # Home feed feature
│   │   ├── screens/
│   │   │   ├── main_screen.dart  # Bottom navigation container
│   │   │   └── home_feed_screen.dart
│   │   └── widgets/
│   │       └── video_feed_item.dart
│   │
│   ├── camera/                   # Video creation feature (TikTok-like)
│   │   ├── screens/
│   │   │   ├── camera_screen.dart          # Basic camera
│   │   │   ├── enhanced_camera_screen.dart # Multi-segment recording
│   │   │   ├── video_edit_screen.dart      # Post-recording editing
│   │   │   └── video_share_screen.dart     # Caption & privacy settings
│   │   ├── services/
│   │   │   └── video_creation_service.dart # Video processing logic
│   │   └── widgets/
│   │       ├── camera_controls.dart        # Record button, mode switcher
│   │       ├── camera_effects.dart         # Visual effects overlay
│   │       ├── camera_filters.dart         # Filter carousel
│   │       ├── beauty_controls.dart        # Beauty filter sliders
│   │       ├── speed_controls.dart         # Recording speed selector
│   │       ├── recording_timer.dart        # Recording progress
│   │       ├── text_overlay_editor.dart    # Text editing interface
│   │       ├── sticker_picker.dart         # Sticker selection
│   │       ├── music_picker.dart           # Sound library browser
│   │       └── trim_slider.dart            # Video trimming control
│   │
│   ├── reels/                    # Short-form video viewing
│   │   ├── screens/
│   │   │   └── reels_screen.dart
│   │   └── widgets/
│   │       ├── video_player_widget.dart
│   │       ├── video_sidebar.dart
│   │       └── video_bottom_section.dart
│   │
│   ├── search/                   # Discovery feature
│   │   └── screens/
│   │       └── search_screen.dart
│   │
│   ├── messages/                 # Direct messaging
│   │   ├── screens/
│   │   │   └── messages_screen.dart
│   │   └── widgets/
│   │
│   ├── profile/                  # User profile
│   │   └── screens/
│   │       └── profile_screen.dart
│   │
│   ├── collab/                   # Collaboration rooms
│   │   └── screens/
│   │       └── collab_room_screen.dart
│   │
│   ├── stories/                  # Stories feature
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── vibe/                     # VIB3 unique features
│   │   └── screens/
│   │       └── vibe_meter_screen.dart
│   │
│   └── time_capsule/             # Time capsule feature
│       └── screens/
│           └── time_capsule_screen.dart
│
└── main.dart                     # App entry point
```

## Feature Modules

### 1. Camera Module (`features/camera/`)
**Purpose**: Complete video creation system similar to TikTok

**Key Components**:
- **Enhanced Camera Screen**: Multi-segment recording with effects
- **Video Edit Screen**: Post-recording editing (text, stickers, music)
- **Video Share Screen**: Caption, tags, privacy settings
- **Video Creation Service**: Handles video processing and effects

**Dependencies**:
- `camera` package for recording
- `video_player` for playback
- `flutter_animate` for animations
- Core services (auth, storage, post)

### 2. Feed Module (`features/feed/`)
**Purpose**: Main navigation and content feed

**Key Components**:
- **Main Screen**: Bottom navigation container
- **Home Feed Screen**: Personalized content feed
- **Video Feed Item**: Individual post display

**Dependencies**:
- Recommendation engine for personalized content
- Feed service for data management

### 3. Recommendation System (`core/services/`)
**Purpose**: AI-powered content recommendation

**Key Components**:
- **Recommendation Engine**: Calculates video scores based on multiple factors
- **Interaction Tracking Service**: Records user behavior (views, likes, watch time)

**Dependencies**:
- Post model for content data
- User preferences tracking

## Best Practices

### 1. Feature Isolation
- Each feature should be self-contained in its directory
- Minimize cross-feature dependencies
- Use dependency injection for services

### 2. State Management
- Use Provider for app-wide state (auth, user data)
- Use local state for feature-specific data
- Consider Riverpod or Bloc for complex features

### 3. Navigation
- All routes defined in `app_router.dart`
- Use GoRouter for type-safe navigation
- Full-screen modals for camera/video features

### 4. Styling
- All colors and themes in `app_theme.dart`
- Consistent use of theme colors
- Reusable widget styles

### 5. API Integration
- All API calls through `api_service.dart`
- Service classes handle business logic
- Models handle data serialization

## Working Guidelines

### When Adding New Features:
1. Create a new directory under `features/`
2. Keep all related screens, widgets, and services together
3. Update `app_router.dart` for new routes
4. Document dependencies in this file

### When Modifying Existing Features:
1. Work within the feature's directory
2. Don't modify core services unless necessary
3. Test changes in isolation
4. Update documentation if structure changes

### Common Issues to Avoid:
1. **Circular Dependencies**: Keep features independent
2. **God Classes**: Split large widgets into smaller components
3. **Hard-coded Values**: Use theme and config files
4. **Direct API Calls**: Always use service classes

## Current Feature Status

✅ **Completed**:
- Basic app structure and navigation
- Authentication flow
- Camera and video creation (TikTok-like)
- Video editing tools
- Recommendation algorithm
- User interaction tracking

🚧 **In Progress**:
- Video processing (filters, effects)
- Social features (comments, likes)
- Real-time messaging

📋 **Planned**:
- Live streaming
- Collaboration rooms
- Time capsule feature
- Advanced analytics

## Testing Strategy

### Unit Tests
- Test services independently
- Mock dependencies
- Focus on business logic

### Widget Tests
- Test UI components in isolation
- Verify user interactions
- Check responsive design

### Integration Tests
- Test complete user flows
- Verify navigation
- Check data persistence

## Performance Considerations

1. **Video Loading**: Implement lazy loading and caching
2. **Memory Management**: Dispose controllers properly
3. **State Updates**: Use selective rebuilds
4. **API Calls**: Implement proper pagination
5. **Image/Video Compression**: Optimize before upload