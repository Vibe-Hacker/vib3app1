# Running the VIB3 App

## Prerequisites
- Flutter SDK installed
- Android Studio or VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

## Commands to Run

### 1. Get Dependencies
```bash
cd D:\VIB3_Project\vib3app1
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Troubleshooting

### FFmpeg Issue
The FFmpeg dependency has been temporarily disabled to avoid build issues. The multi-trim feature currently:
- Saves trim data locally using SharedPreferences
- Provides trim instructions that can be processed server-side
- Shows UI for multi-segment selection without actual video processing

To enable FFmpeg in the future:
1. Uncomment `ffmpeg_kit_flutter_min: ^6.0.3` in pubspec.yaml
2. Uncomment imports in `video_processing_service.dart`
3. Run `flutter pub get`

### Build Errors
If you encounter build errors:
1. Clean the project: `flutter clean`
2. Delete the `.dart_tool` folder
3. Run `flutter pub get` again
4. Try building again

### Android Specific
Make sure your `android/build.gradle` includes:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

## Features Working Without FFmpeg

### Multi-Trim UI
- Visual segment selection
- Preview playback
- Segment management
- Color-coded segments

### Trim Data Storage
- Saves segment information
- Exports trim instructions
- Can be sent to server for processing

### Future Implementation
When FFmpeg is integrated or server-side processing is available:
- Actual video segment extraction
- Concatenation of segments
- Export of processed video

## Testing Multi-Trim Feature

1. Record or select a video
2. In edit screen, tap "Trim" in bottom tools
3. Select "Multi-Trim" option
4. Add segments using "Add Segment" button
5. Adjust segment boundaries
6. Play to preview selection
7. Tap check mark to save trim data

The trim data will be saved and can be accessed via:
```dart
final trimService = VideoTrimService();
final pendingJobs = await trimService.getPendingTrimJobs();
```