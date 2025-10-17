# VIB3 Dependencies Documentation

## Overview
This document tracks all package dependencies and their usage across different features to prevent version conflicts and breaking changes.

## Core Dependencies

### State Management
- **provider: ^6.0.0**
  - Used for: Global state (auth, user data)
  - Features: All features
  - Critical for: Authentication flow

### Navigation
- **go_router: ^10.0.0**
  - Used for: App navigation
  - Features: All features
  - Configuration: `lib/app/routes/app_router.dart`

### Storage
- **hive_flutter: ^1.1.0**
  - Used for: Local data persistence
  - Features: Auth tokens, user preferences
  - Service: `lib/core/services/storage_service.dart`

### Networking
- **http: ^1.0.0**
  - Used for: API calls
  - Service: `lib/core/services/api_service.dart`
  - All API interactions go through this service

## Feature-Specific Dependencies

### Camera & Video Creation
- **camera: ^0.10.0**
  - Used for: Video recording
  - Features: Camera screens
  - Critical for: Recording functionality

- **video_player: ^2.7.0**
  - Used for: Video playback
  - Features: Feed, Reels, Video editing
  - Performance: Implement caching

- **permission_handler: ^10.0.0**
  - Used for: Camera/microphone permissions
  - Features: Camera screens
  - Platform specific setup required

- **image_picker: ^1.0.0**
  - Used for: Gallery access
  - Features: Profile, Camera
  - Alternative to camera recording

### UI & Animations
- **flutter_animate: ^4.0.0**
  - Used for: Smooth animations
  - Features: All UI transitions
  - Performance: Use sparingly

- **cached_network_image: ^3.0.0**
  - Used for: Image caching
  - Features: Feed, Profile
  - Reduces bandwidth usage

- **shimmer: ^3.0.0**
  - Used for: Loading placeholders
  - Features: Feed, Search
  - Better UX during loading

### Video Processing (Planned)
- **ffmpeg_kit_flutter: ^5.0.0**
  - Used for: Video processing
  - Features: Video editing
  - Note: Large package, platform specific

- **video_compress: ^3.0.0**
  - Used for: Video compression
  - Features: Upload optimization
  - Reduces upload time/bandwidth

## Package Conflicts & Solutions

### Known Issues
1. **camera + video_player**
   - Conflict: Both use platform views
   - Solution: Proper disposal of controllers
   - Affected: Camera to video playback transition

2. **go_router + Provider**
   - Conflict: Context access in redirect
   - Solution: Use navigatorKey for global access
   - Affected: Auth redirects

## Platform-Specific Setup

### Android
```gradle
// android/app/build.gradle
minSdkVersion 21  // Required for camera
compileSdkVersion 33
```

### iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>VIB3 needs camera access to record videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>VIB3 needs microphone access to record audio</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>VIB3 needs photo library access to save videos</string>
```

## Dependency Update Strategy

### Before Updating
1. Check changelog for breaking changes
2. Review dependent features
3. Test on both platforms
4. Update in separate branch

### Testing After Updates
1. Camera functionality
2. Video playback
3. Navigation flows
4. State persistence

## Future Dependencies

### Planned Additions
- **web_socket_channel**: For real-time features
- **firebase_messaging**: For push notifications
- **flutter_local_notifications**: For local notifications
- **geolocator**: For location-based features
- **flutter_sound**: For audio recording

### Under Consideration
- **mux_flutter**: Professional video streaming
- **agora_rtc_engine**: Live streaming
- **flutter_webrtc**: Video calls

## Performance Guidelines

### Large Packages
1. **ffmpeg_kit_flutter**: ~100MB
   - Consider: On-demand download
   - Alternative: Server-side processing

2. **agora_rtc_engine**: ~50MB
   - Consider: Separate app flavor
   - Alternative: WebRTC

### Memory Management
1. Dispose video controllers
2. Clear image cache periodically
3. Limit concurrent video players
4. Use thumbnail previews

## Security Considerations

### API Keys
- Never commit API keys
- Use environment variables
- Implement key rotation

### User Data
- Encrypt sensitive data (Hive)
- Clear cache on logout
- Implement secure storage

### Network
- Certificate pinning for API
- Implement request signing
- Use HTTPS only

## Maintenance Schedule

### Weekly
- Check for security updates
- Review crash reports
- Monitor deprecated APIs

### Monthly
- Update minor versions
- Review performance metrics
- Clean unused dependencies

### Quarterly
- Major version updates
- Platform SDK updates
- Dependency audit