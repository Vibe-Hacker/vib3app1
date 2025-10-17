import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/camera_filters.dart';
import '../widgets/camera_effects.dart';
import '../widgets/camera_controls.dart';
import '../widgets/recording_timer.dart';
import '../widgets/speed_controls.dart';
import '../widgets/beauty_controls.dart';
import '../services/video_creation_service.dart';

class EnhancedCameraScreen extends StatefulWidget {
  const EnhancedCameraScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Camera controllers
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  
  // Recording state
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  final int _maxRecordingSeconds = 60;
  
  // Video segments for multi-clip recording
  final List<VideoSegment> _videoSegments = [];
  
  // Creation modes
  RecordingMode _recordingMode = RecordingMode.normal;
  RecordingSpeed _recordingSpeed = RecordingSpeed.normal;
  
  // Effects and filters
  String? _selectedFilter;
  String? _selectedEffect;
  double _beautyLevel = 0.0;
  bool _flashEnabled = false;
  
  // UI state
  bool _showSpeedOptions = false;
  bool _showTimerOptions = false;
  bool _showBeautyOptions = false;
  int _countdownSeconds = 0;
  
  // Services
  late VideoCreationService _videoCreationService;
  
  // Animation controllers
  late AnimationController _recordButtonController;
  late AnimationController _effectsPanelController;
  
  @override
  void initState() {
    super.initState();
    // Hide system UI for immersive camera experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    WidgetsBinding.instance.addObserver(this);
    _videoCreationService = VideoCreationService();
    
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _effectsPanelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _initializeCamera();
  }
  
  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    _recordButtonController.dispose();
    _effectsPanelController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setupCameraController(_currentCameraIndex);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  Future<void> _setupCameraController(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;
    
    final camera = _cameras![cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error setting up camera: $e');
    }
  }
  
  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _setupCameraController(_currentCameraIndex);
    HapticFeedback.selectionClick();
  }
  
  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
    
    await _cameraController!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
    HapticFeedback.selectionClick();
  }
  
  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (_countdownSeconds > 0) {
      await _startCountdown();
      return;
    }
    
    try {
      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      
      _recordButtonController.forward();
      HapticFeedback.mediumImpact();
      
      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
        
        if (_recordingSeconds >= _maxRecordingSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }
  
  Future<void> _pauseRecording() async {
    if (!_isRecording || _cameraController == null) return;
    
    try {
      if (_isPaused) {
        await _cameraController!.resumeVideoRecording();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
          
          if (_recordingSeconds >= _maxRecordingSeconds) {
            _stopRecording();
          }
        });
      } else {
        await _cameraController!.pauseVideoRecording();
        _recordingTimer?.cancel();
      }
      
      setState(() {
        _isPaused = !_isPaused;
      });
      
      HapticFeedback.selectionClick();
    } catch (e) {
      // If pause not supported, stop and create segment
      await _stopAndSaveSegment();
    }
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;
    
    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      _recordingTimer?.cancel();
      _recordButtonController.reverse();
      
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      
      HapticFeedback.mediumImpact();
      
      // Add to segments
      _videoSegments.add(VideoSegment(
        path: videoFile.path,
        duration: _recordingSeconds,
        speed: _recordingSpeed,
      ));
      
      // Automatically navigate to edit screen after recording
      // This provides a more streamlined experience
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateToEditScreen();
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
  
  Future<void> _stopAndSaveSegment() async {
    if (!_isRecording || _cameraController == null) return;
    
    final XFile videoFile = await _cameraController!.stopVideoRecording();
    
    _recordingTimer?.cancel();
    
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    
    // Add to segments
    _videoSegments.add(VideoSegment(
      path: videoFile.path,
      duration: _recordingSeconds,
      speed: _recordingSpeed,
    ));
  }
  
  Future<void> _startCountdown() async {
    setState(() {
      _showTimerOptions = false;
    });
    
    for (int i = _countdownSeconds; i > 0; i--) {
      if (!mounted) break;
      
      setState(() {
        _countdownSeconds = i;
      });
      
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(seconds: 1));
    }
    
    setState(() {
      _countdownSeconds = 0;
    });
    
    if (mounted) {
      _startRecording();
    }
  }
  
  void _deleteLastSegment() {
    if (_videoSegments.isEmpty) return;
    
    setState(() {
      _videoSegments.removeLast();
    });
    
    HapticFeedback.mediumImpact();
  }
  
  void _navigateToEditScreen() {
    if (_videoSegments.isEmpty) return;
    
    // Navigate to video edit screen with segments
    context.push('/video-edit', extra: _videoSegments);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),
          
          // Recording UI Overlay
          if (_isRecording) _buildRecordingOverlay(),
          
          // Top Controls
          _buildTopControls(),
          
          // Side Controls
          _buildSideControls(),
          
          // Bottom Controls
          _buildBottomControls(),
          
          // Speed Options Panel
          if (_showSpeedOptions) _buildSpeedOptions(),
          
          // Timer Options Panel
          if (_showTimerOptions) _buildTimerOptions(),
          
          // Beauty Options Panel
          if (_showBeautyOptions) _buildBeautyOptions(),
          
          // Countdown Display
          if (_countdownSeconds > 0) _buildCountdownDisplay(),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        
        // Apply filter overlay
        if (_selectedFilter != null)
          CameraFilterOverlay(filter: _selectedFilter!),
        
        // Apply effects
        if (_selectedEffect != null)
          CameraEffectOverlay(effect: _selectedEffect!),
      ],
    );
  }
  
  Widget _buildRecordingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 4,
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scaleXY(
          begin: 1.0,
          end: 0.98,
          duration: 1.seconds,
        ),
      ),
    );
  }
  
  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.close, size: 28),
                color: Colors.white,
              ),
              
              // Recording time and segments
              if (_isRecording || _videoSegments.isNotEmpty)
                RecordingTimer(
                  seconds: _recordingSeconds,
                  maxSeconds: _maxRecordingSeconds,
                  segmentCount: _videoSegments.length,
                ),
              
              // Settings
              IconButton(
                onPressed: () {
                  // TODO: Show camera settings
                },
                icon: const Icon(Icons.settings_outlined, size: 28),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          // Flip camera
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: _toggleCamera,
          ),
          
          const SizedBox(height: 24),
          
          // Speed
          _buildControlButton(
            icon: Icons.speed,
            label: 'Speed',
            onTap: () {
              setState(() {
                _showSpeedOptions = !_showSpeedOptions;
                _showTimerOptions = false;
                _showBeautyOptions = false;
              });
            },
            isActive: _recordingSpeed != RecordingSpeed.normal,
          ),
          
          const SizedBox(height: 24),
          
          // Beauty
          _buildControlButton(
            icon: Icons.face_retouching_natural,
            label: 'Beauty',
            onTap: () {
              setState(() {
                _showBeautyOptions = !_showBeautyOptions;
                _showSpeedOptions = false;
                _showTimerOptions = false;
              });
            },
            isActive: _beautyLevel > 0,
          ),
          
          const SizedBox(height: 24),
          
          // Filters
          _buildControlButton(
            icon: Icons.filter_vintage,
            label: 'Filters',
            onTap: () {
              _showFiltersSheet();
            },
            isActive: _selectedFilter != null,
          ),
          
          const SizedBox(height: 24),
          
          // Timer
          _buildControlButton(
            icon: Icons.timer,
            label: 'Timer',
            onTap: () {
              setState(() {
                _showTimerOptions = !_showTimerOptions;
                _showSpeedOptions = false;
                _showBeautyOptions = false;
              });
            },
            isActive: _countdownSeconds > 0,
          ),
          
          const SizedBox(height: 24),
          
          // Flash
          _buildControlButton(
            icon: _flashEnabled ? Icons.flash_on : Icons.flash_off,
            label: 'Flash',
            onTap: _toggleFlash,
            isActive: _flashEnabled,
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0),
    );
  }
  
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Effects, Upload, Templates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Effects
                  _buildBottomOption(
                    icon: Icons.auto_awesome,
                    label: 'Effects',
                    onTap: _showEffectsSheet,
                  ),
                  
                  // Record button
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    onLongPress: _isRecording ? null : _startRecording,
                    onLongPressEnd: (_) => _isRecording ? _pauseRecording() : null,
                    child: AnimatedBuilder(
                      animation: _recordButtonController,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              _recordButtonController.value * 8,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Upload
                  _buildBottomOption(
                    icon: Icons.photo_library,
                    label: 'Upload',
                    onTap: () {
                      // TODO: Upload from gallery
                    },
                  ),
                ],
              ),
              
              // Segment controls
              if (_videoSegments.isNotEmpty && !_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Delete last segment
                      TextButton.icon(
                        onPressed: _deleteLastSegment,
                        icon: const Icon(Icons.backspace, color: Colors.white),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Done - go to edit
                      ElevatedButton.icon(
                        onPressed: _navigateToEditScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        icon: const Icon(Icons.check),
                        label: Text('Next (${_videoSegments.length})'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.primaryColor : Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildBottomOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpeedOptions() {
    return SpeedControlPanel(
      currentSpeed: _recordingSpeed,
      onSpeedChanged: (speed) {
        setState(() {
          _recordingSpeed = speed;
          _showSpeedOptions = false;
        });
      },
    );
  }
  
  Widget _buildTimerOptions() {
    return Positioned(
      right: 80,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildTimerOption(3),
            const SizedBox(height: 8),
            _buildTimerOption(10),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.2, end: 0),
    );
  }
  
  Widget _buildTimerOption(int seconds) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _countdownSeconds = seconds;
          _showTimerOptions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _countdownSeconds == seconds
              ? AppTheme.primaryColor
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${seconds}s',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildBeautyOptions() {
    return BeautyControlPanel(
      beautyLevel: _beautyLevel,
      onBeautyChanged: (level) {
        setState(() {
          _beautyLevel = level;
        });
      },
      onClose: () {
        setState(() {
          _showBeautyOptions = false;
        });
      },
    );
  }
  
  Widget _buildCountdownDisplay() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$_countdownSeconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ).animate().scaleXY(
        begin: 0.5,
        end: 1.0,
        duration: 300.ms,
      ),
    );
  }
  
  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSelectionSheet(
        selectedFilter: _selectedFilter,
        onFilterSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showEffectsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EffectSelectionSheet(
        selectedEffect: _selectedEffect,
        onEffectSelected: (effect) {
          setState(() {
            _selectedEffect = effect;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

// Enums
enum RecordingMode { normal, photo, story, live }
enum RecordingSpeed { slow, verySlow, normal, fast, veryFast }

// Video segment model
class VideoSegment {
  final String path;
  final int duration;
  final RecordingSpeed speed;
  
  VideoSegment({
    required this.path,
    required this.duration,
    required this.speed,
  });
}