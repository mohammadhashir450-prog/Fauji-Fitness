# 🔧 JYM PRO - Technical Documentation

## Project Structure

```
jym_app/
├── lib/
│   ├── main.dart                 # App entry point, AppShell navigation
│   ├── models/
│   │   ├── user.dart            # UserProfile model, Goal enum
│   │   └── weight_entry.dart    # WeightEntry model
│   ├── providers/
│   │   ├── user_provider.dart   # User data state management
│   │   └── weight_provider.dart # Weight tracking state management
│   ├── screens/
│   │   ├── splash_screen.dart   # Onboarding animation
│   │   ├── dashboard_screen.dart # Home screen with metrics
│   │   ├── weight_tracker_screen.dart # Weight logging
│   │   ├── community_screen.dart # Social features
│   │   ├── profile_screen.dart  # User profile management
│   │   └── workouts_screen.dart # Workout recommendations
│   ├── services/
│   │   └── storage_service.dart # Local data persistence
│   └── widgets/
│       └── fitness_widgets.dart # Reusable UI components
├── pubspec.yaml                 # Dependencies configuration
└── README.md                    # Project overview
```

---

## Technology Stack

### Framework & Language
- **Flutter**: 3.10.7+
- **Dart**: Latest compatible version

### Key Dependencies
- **provider** (6.0.5): State management
- **shared_preferences** (2.1.1): Local data storage
- **fl_chart** (0.55.2): Data visualization
- **intl** (0.18.1): Internationalization & date formatting
- **uuid** (3.0.7): Unique ID generation

---

## Architecture

### State Management (Provider)
```
MyApp
├── MultiProvider
│   ├── ChangeNotifierProvider<UserProvider>
│   └── ChangeNotifierProvider<WeightProvider>
└── MaterialApp
    └── AppShell (IndexedStack Navigation)
        ├── DashboardScreen
        ├── WeightTrackerScreen
        ├── CommunityScreen
        └── ProfileScreen
```

### Navigation Pattern
- **Bottom Tab Navigation**: Primary navigation via IndexedStack
- **No Deep Linking**: Uses index-based navigation
- **Drawer Navigation**: Quick access from Dashboard

---

## Data Models

### UserProfile
```dart
class UserProfile {
  final String id;
  String name;
  DateTime? dob;
  String sex;              // 'male', 'female', 'other'
  double? heightCm;
  String? avatarUrl;
  Goal goal;               // lose, maintain, gain
  
  double? get heightM => heightCm == null ? null : heightCm! / 100.0;
}

enum Goal { lose, maintain, gain }
```

### WeightEntry
```dart
class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
}
```

---

## Providers

### UserProvider
**Purpose**: Manage user profile data

**Methods**:
- `load()`: Load user from storage
- `createOrUpdate()`: Save or update user profile

**Properties**:
- `user`: Current UserProfile or null

### WeightProvider
**Purpose**: Manage weight entries

**Methods**:
- `load()`: Load weight history from storage
- `addWeight()`: Save new weight entry

**Properties**:
- `entries`: List of WeightEntry objects

---

## Services

### StorageService
**Purpose**: Handle local data persistence via SharedPreferences

**Methods**:
- `loadUser()`: Retrieve saved user profile
- `saveUser()`: Persist user profile
- `loadWeightEntries()`: Retrieve weight history
- `addWeightEntry()`: Save weight entry

**Storage Keys**:
- `user_profile`: JSON serialized UserProfile
- `weight_entries`: JSON array of WeightEntry objects

---

## Screens & Features

### 1. SplashScreen
- **Purpose**: Onboarding/intro animation
- **Duration**: 2 seconds
- **Navigation**: Transitions to AppShell
- **Features**:
  - Animated logo
  - Brand messaging
  - Loading indicator

### 2. DashboardScreen
- **Purpose**: Home screen with overview
- **Features**:
  - Progress ring (circular chart)
  - Daily metrics (calories, heart points, active mins)
  - Mini metric cards (deadlift, pace, volume, recovery)
  - Body metrics grid (steps, heart rate, BMI, calories)
  - Workout of the day banner
  - Favorites carousel
  - Drawer navigation menu

### 3. WeightTrackerScreen
- **Purpose**: Weight logging and tracking
- **Features**:
  - Current weight display
  - Log weight form dialog
  - Weight history chart (line chart)
  - Metrics grid (BMI, body fat %, goal)
  - Recent logs list with timestamps
  - Range toggle (Month/Week/Year)

### 4. CommunityScreen
- **Purpose**: Social fitness features
- **Features**:
  - Hero banner with call-to-action
  - Clubs and challenges metrics
  - Trending communities cards
  - Community feed with posts
  - Member information

### 5. ProfileScreen
- **Purpose**: User profile management
- **Features**:
  - Profile hero card with stats
  - Profile metrics display
  - Editable form:
    - Name (TextFormField)
    - Height in cm (numeric input)
    - Sex (dropdown)
    - Goal (dropdown)
  - Save functionality with feedback

### 6. WorkoutsScreen
- **Purpose**: Personalized workout recommendations
- **Features**:
  - Neon green themed banner
  - Personalized suggestions based on:
    - Fitness goal (Lose/Maintain/Gain)
    - BMI category
  - Workout cards with:
    - Duration/intensity tag
    - Description
    - Forward navigation arrow

---

## UI Components (fitness_widgets.dart)

### FitnessStatCard
- **Purpose**: Display metric with icon and value
- **Props**: icon, title, value, subtitle, accent color

### NeonSectionTitle
- **Purpose**: Section header with optional action
- **Props**: title, actionLabel, onAction callback

### NeonPillToggle
- **Purpose**: Segmented control for options
- **Props**: labels, selectedIndex, onChanged callback

### NeonMetricTile
- **Purpose**: 3x3 grid metric display
- **Props**: title, value, subtitle, icon, accent

### NeonLogTile
- **Purpose**: Log entry in list
- **Props**: date, time, weight, diff, accent

---

## Color Palette

### Primary Colors
```dart
// Neon Green Accent
const Color neonGreen = Color(0xFFC7F000);

// Dark Backgrounds
const Color bgDark = Color(0xFF0B0D0A);
const Color bgDarker = Color(0xFF0B1020);

// Card Backgrounds
const Color cardDark = Color(0xFF171816);
const Color cardDarker = Color(0xFF121826);

// Borders & Accents
const Color borderLight = Color(0xFFC7F000).withAlpha(38);  // 15% opacity
```

### Text Colors
```dart
const Color textPrimary = Colors.white;
const Color textSecondary = Color(0xFFD7DBE5);  // Light gray
const Color textTertiary = Color(0xFFAFB6C4);   // Medium gray
const Color textQuaternary = Colors.white54;    // Dark gray
```

---

## Typography

### Text Styles (from theme)
```dart
headlineLarge:   fontSize: 32, fontWeight: w800
headlineMedium:  fontSize: 24, fontWeight: w700
titleLarge:      fontSize: 18, fontWeight: w700
bodyLarge:       fontSize: 16, color: textSecondary
bodyMedium:      fontSize: 14, color: textTertiary
```

### Custom Styles
- Section titles: 18px, w900, 0.3 letter spacing
- Cards: Rounded corners (14-24px radius)
- Borders: 1px white10 opacity

---

## Navigation Flow

```
SplashScreen (2s)
    ↓
AppShell
├── DashboardScreen
│   └── Drawer Menu
│       ├── Home
│       ├── Weight Tracker
│       ├── Community
│       └── Profile
├── WeightTrackerScreen
│   └── Log Weight Dialog
├── CommunityScreen
└── ProfileScreen
    └── Edit Form Dialog
```

---

## State Flow

### On App Launch
```
1. WidgetsFlutterBinding.ensureInitialized()
2. MyApp initializes MultiProvider
3. UserProvider.load() → loads from storage
4. WeightProvider.load() → loads from storage
5. SplashScreen displays (2 seconds)
6. Transitions to AppShell
7. Screens access state via context.watch/read
```

### On Weight Entry
```
1. User enters weight in dialog form
2. Form validation
3. WeightProvider.addWeight() called
4. Saved to storage via StorageService
5. Provider notifies listeners
6. UI updates with new entry
7. Dialog closes, list refreshes
```

### On Profile Update
```
1. User edits form fields
2. User taps SAVE PROFILE
3. Form validation
4. UserProvider.createOrUpdate() called
5. Saved to storage via StorageService
6. Provider notifies listeners
7. Dashboard updates BMI/recommendations
8. SnackBar shows confirmation
```

---

## Performance Optimizations

### Navigation
- **IndexedStack**: Keeps all screens in memory but efficient rendering
- **const Constructors**: Used throughout for memory efficiency
- **Provider**: Selective listening with watch vs read

### Data Management
- **Local Storage**: Avoids network calls
- **Lazy Loading**: Data loaded on first access
- **Efficient Serialization**: JSON for storage

### UI Rendering
- **CustomPaint**: Efficient chart rendering
- **NetworkImage**: Cached by Flutter
- **ListView**: Efficient list rendering with shrinkWrap

---

## Error Handling

### BuildContext Safety
```dart
// Correct pattern used:
final provider = context.read<Provider>();
await asyncOperation();
if (!mounted) return;
// Use provider state safely
```

### Form Validation
```dart
if (!_formKey.currentState!.validate()) return;
_formKey.currentState!.save();
// Process saved values
```

### Navigation Safety
```dart
if (mounted) Navigator.pop(context);
```

---

## Testing Recommendations

### Unit Tests
- Model serialization/deserialization
- Provider business logic
- Storage service operations

### Widget Tests
- Screen rendering
- Button interactions
- Form validation

### Integration Tests
- Full app flow
- Navigation between screens
- Data persistence

---

## Build & Deployment

### Development Build
```bash
flutter pub get
flutter run
```

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### Platform-Specific
```bash
# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

---

## Common Tasks

### Adding a New Screen
1. Create file in `screens/` folder
2. Extend `StatelessWidget` or `StatefulWidget`
3. Add to `_pages` list in AppShell
4. Update bottom nav destinations if needed

### Adding New Metrics
1. Define in appropriate Provider
2. Add calculation logic
3. Create UI widget
4. Add to relevant screen

### Updating Colors
1. Edit color constants at top of theme
2. Update all references (usually automatic)
3. Test on multiple screens

---

## Debugging

### Enable Verbose Logging
```bash
flutter run -v
```

### Use DevTools
```bash
flutter pub global activate devtools
devtools
```

### Hot Reload
- Press 'r' in terminal while running
- Press 'R' for full restart

---

## Dependencies Notes

### provider
- **Why**: Robust state management
- **Alternative**: Riverpod, Bloc
- **Usage**: ChangeNotifierProvider for simplicity

### shared_preferences
- **Why**: Simple local storage
- **Alternative**: Hive, SQLite
- **Limitation**: Not for large data

### fl_chart
- **Why**: Professional charts
- **Alternative**: Syncfusion, charts_flutter
- **Performance**: Efficient rendering

---

## Future Enhancements

1. **Backend Sync**: Firebase integration
2. **Social Features**: Real user interactions
3. **Advanced Analytics**: ML-based recommendations
4. **Wearable Integration**: Smartwatch support
5. **Offline Mode**: Enhanced offline functionality
6. **Push Notifications**: Reminders and alerts
7. **Multi-language**: i18n support
8. **Dark/Light Mode**: Theme toggle

---

**Version**: 1.0.0
**Last Updated**: May 12, 2025
**Maintainers**: Development Team
**Status**: Production Ready ✓
