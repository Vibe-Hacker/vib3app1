# Multi-Trim Video Feature

## Overview
The multi-trim feature allows users to create multiple segments from a single video, similar to advanced video editing apps. Users can:
- Select multiple non-overlapping segments from a video
- Preview each segment individually
- Play all segments in sequence
- Export the final video with only the selected segments

## How It Works

### 1. Single Trim (Basic)
- Users can use the standard trim tool to select a single continuous segment
- Simple range slider interface
- Real-time video preview

### 2. Multi-Trim (Advanced)
- Users can create up to 8 different segments
- Each segment has a unique color for easy identification
- Segments cannot overlap
- Visual timeline shows all segments

## User Interface

### Multi-Trim Slider Components:
1. **Video Preview**
   - Shows the current video position
   - Play/pause controls
   - Automatically loops through all segments when playing

2. **Timeline**
   - Visual representation of the entire video
   - Colored segments show selected portions
   - White line indicates current playback position
   - Thumbnails (placeholder for future implementation)

3. **Segment List**
   - Horizontal scrollable list of all segments
   - Shows segment number and duration
   - Tap to select and edit a segment

4. **Segment Editor**
   - Range slider to adjust start/end points
   - Delete button to remove segment
   - Time labels showing exact timestamps

5. **Add Segment**
   - Button to add new segments
   - Automatically finds available space
   - Visual preview before confirming

## Implementation Details

### Files Created/Modified:

1. **`multi_trim_slider.dart`**
   - Main widget for multi-segment trimming
   - Manages segment state and playback
   - Handles user interactions

2. **`video_processing_service.dart`**
   - FFmpeg integration for video processing
   - Methods for:
     - Single trim
     - Multi-segment trim
     - Text overlay
     - Audio merging
     - Speed adjustment
     - Thumbnail extraction

3. **`video_edit_screen.dart`**
   - Added multi-trim button in trim tools
   - Integrated multi-trim slider
   - Passes trim segments to share screen

## Video Processing Flow

1. **Segment Extraction**
   - Each segment is extracted as a separate video file
   - Uses FFmpeg with precise timestamps

2. **Concatenation**
   - All segments are concatenated in order
   - Creates a seamless final video

3. **Cleanup**
   - Temporary files are deleted after processing
   - Error handling ensures no orphaned files

## Usage Example

```dart
// Initialize multi-trim
MultiTrimSlider(
  videoController: _videoController,
  videoDuration: _videoDuration,
  initialSegments: [],
  onSegmentsChanged: (segments) {
    // Handle segment updates
  },
  onClose: () {
    // Close the trimmer
  },
)

// Process video with segments
final processedVideo = await VideoProcessingService().multiTrimVideo(
  inputPath: originalVideoPath,
  segments: trimSegments,
  videoDuration: videoDuration,
);
```

## Technical Considerations

### Performance
- Segments are processed sequentially to avoid memory issues
- FFmpeg commands are optimized for speed
- Temporary files are cleaned up immediately

### Limitations
- Maximum 8 segments (UI constraint)
- Segments must be at least 0.1 seconds apart
- Processing time increases with segment count

### Future Enhancements
1. **Video Thumbnails**
   - Generate real thumbnails for timeline
   - Show frame preview when dragging

2. **Transitions**
   - Add transitions between segments
   - Fade, dissolve, slide effects

3. **Segment Reordering**
   - Drag to reorder segments
   - Preview reordered sequence

4. **Templates**
   - Save segment patterns as templates
   - Quick apply common trim patterns

## Error Handling

- Overlapping segments are prevented
- Minimum segment duration enforced
- FFmpeg errors are caught and reported
- Fallback to original video on processing failure

## Platform Considerations

### iOS
- Requires iOS 11.0+
- Uses hardware acceleration when available

### Android
- Requires API 21+
- May need additional permissions for file access

### Web
- FFmpeg not available on web
- Would need server-side processing

## Testing Checklist

- [ ] Can add multiple segments
- [ ] Segments don't overlap
- [ ] Preview plays correctly
- [ ] Individual segment playback works
- [ ] Delete segment functionality
- [ ] Export creates correct video
- [ ] Memory usage is reasonable
- [ ] UI updates smoothly
- [ ] Error messages are clear