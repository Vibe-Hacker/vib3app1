# VIB3 Feature Development Guide

## How to Work on Features Without Breaking Others

### 1. Camera/Video Creation Module

#### Directory: `lib/features/camera/`

**Safe to Modify**:
- Any file within `camera/widgets/`
- Styling in widget files
- Adding new effects/filters
- UI improvements

**Requires Careful Testing**:
- `enhanced_camera_screen.dart` - Core recording logic
- `video_creation_service.dart` - Video processing
- Navigation flow changes

**Do NOT Modify Without Review**:
- Camera initialization logic
- Video segment handling
- Navigation to/from camera screens

**Testing Checklist**:
- [ ] Camera opens without bottom nav
- [ ] Recording starts/stops properly
- [ ] Effects apply correctly
- [ ] Navigation to edit screen works
- [ ] Multiple segments record properly
- [ ] Memory is properly released

#### Common Issues & Fixes:
```dart
// Issue: Bottom navigation showing
// Fix: Use context.go() instead of context.push()

// Issue: Camera not disposing
// Fix: Always dispose in dispose() method
@override
void dispose() {
  _controller?.dispose();
  super.dispose();
}

// Issue: Video not playing in edit
// Fix: Initialize video controller properly
await _videoController.initialize();
```

### 2. Feed & Recommendation Module

#### Directory: `lib/features/feed/` & `lib/core/services/recommendation_engine.dart`

**Safe to Modify**:
- Feed item styling
- Loading states
- Pull-to-refresh logic
- Recommendation weights

**Requires Careful Testing**:
- Feed pagination
- Video pre-loading
- Recommendation algorithm
- User interaction tracking

**Do NOT Modify Without Review**:
- Main navigation structure
- Provider setup
- API response handling

**Testing Checklist**:
- [ ] Feed loads properly
- [ ] Videos play automatically
- [ ] Pagination works
- [ ] Pull-to-refresh functions
- [ ] Interactions are tracked
- [ ] Memory usage is stable

### 3. Authentication Module

#### Directory: `lib/features/auth/` & `lib/core/services/auth_service.dart`

**Safe to Modify**:
- UI styling
- Form validation
- Error messages
- Loading states

**Requires Careful Testing**:
- Login/signup flow
- Token management
- Auto-login logic
- Logout cleanup

**Do NOT Modify Without Review**:
- Token storage
- API authentication
- Route guards
- Provider setup

### 4. Profile Module

#### Directory: `lib/features/profile/`

**Safe to Modify**:
- Profile UI layout
- Stats display
- Tab content
- animations

**Requires Careful Testing**:
- Profile data loading
- Image upload
- Profile editing
- Follow/unfollow logic

## Adding New Features

### Step 1: Create Feature Structure
```bash
# Create directories
mkdir -p lib/features/new_feature/{screens,widgets,services,models}

# Create main screen
touch lib/features/new_feature/screens/new_feature_screen.dart
```

### Step 2: Basic Screen Template
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';

class NewFeatureScreen extends StatefulWidget {
  const NewFeatureScreen({Key? key}) : super(key: key);

  @override
  State<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends State<NewFeatureScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize feature
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('New Feature'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          // Feature content
        ),
      ),
    );
  }
}
```

### Step 3: Add Route
```dart
// In app_router.dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) => const NewFeatureScreen(),
),
```

### Step 4: Create Service (if needed)
```dart
class NewFeatureService {
  final ApiService _apiService = ApiService();
  
  Future<void> performAction() async {
    try {
      final response = await _apiService.post('/endpoint');
      // Handle response
    } catch (e) {
      throw Exception('Failed to perform action: $e');
    }
  }
}
```

## State Management Guidelines

### Local State (useState)
Use for UI-only state:
```dart
bool _isLoading = false;
int _selectedIndex = 0;
```

### Provider State
Use for shared state:
```dart
// Read
final authService = context.read<AuthService>();

// Watch (rebuilds on change)
final user = context.watch<AuthService>().currentUser;
```

### Service Pattern
Keep business logic in services:
```dart
class FeatureService extends ChangeNotifier {
  List<Item> _items = [];
  
  List<Item> get items => _items;
  
  Future<void> loadItems() async {
    _items = await _apiService.getItems();
    notifyListeners();
  }
}
```

## Performance Best Practices

### 1. Image/Video Loading
```dart
// Use cached images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => Shimmer.fromColors(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// Preload videos
_videoController = VideoPlayerController.network(url)
  ..initialize().then((_) {
    setState(() {});
  });
```

### 2. List Performance
```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
)

// Add keys for stateful widgets
key: ValueKey(item.id),
```

### 3. Memory Management
```dart
// Dispose controllers
@override
void dispose() {
  _videoController?.dispose();
  _animationController?.dispose();
  super.dispose();
}

// Clear cache when needed
imageCache.clear();
```

## Testing Your Changes

### 1. Manual Testing
- Test on both iOS and Android
- Test on different screen sizes
- Test with poor network
- Test memory usage

### 2. Widget Testing
```dart
testWidgets('Feature test', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NewFeatureScreen(),
    ),
  );
  
  expect(find.text('New Feature'), findsOneWidget);
});
```

### 3. Integration Testing
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Full feature flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Test complete user flow
  });
}
```

## Common Pitfalls to Avoid

1. **Don't modify core navigation without testing all flows**
2. **Don't change API response models without updating all usages**
3. **Don't add heavy operations in build methods**
4. **Don't forget to dispose resources**
5. **Don't hardcode values - use theme/config**
6. **Don't skip null checks**
7. **Don't ignore platform differences**

## Git Workflow

### Feature Branch
```bash
# Create feature branch
git checkout -b feature/new-feature-name

# Make changes
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/new-feature-name
```

### Commit Messages
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `style:` UI/styling changes
- `docs:` Documentation
- `test:` Test additions/changes
- `chore:` Maintenance tasks

## Getting Help

1. Check existing patterns in codebase
2. Review documentation files
3. Test thoroughly before merging
4. Ask for code review on complex changes