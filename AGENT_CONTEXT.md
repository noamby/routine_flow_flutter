# Agent Context: Routine Flow Flutter App

This document provides context for AI agents working on this codebase. It contains architectural decisions, implementation details, and debugging information.

---

## 🎯 Application Overview

**Routine Flow** is a Flutter app designed to help families manage daily routines for children. It provides:

- **Task Management**: Morning and evening routines with checkable tasks
- **Multi-Member Support**: Each family member gets their own column/tab with tasks
- **Child Mode**: A locked mode where children can only check tasks, not modify settings
- **Cross-Platform**: Runs on Android, iOS, Web, macOS, Windows, and Linux

---

## 🚀 Quick Start Commands

### Run for Development (Web)

```bash
# Install dependencies
flutter pub get

# Run on web server (accessible from other devices on same network)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

This starts a web server at `http://0.0.0.0:8080`. Access from:
- Same machine: `http://localhost:8080`
- Other devices on network: `http://<your-ip>:8080`

### Build Android APK

```bash
# Set Java (macOS)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Build release
flutter build apk --release --no-tree-shake-icons
```

**Note**: The `--no-tree-shake-icons` flag is required because the app uses dynamic `IconData` in `preferences_service.dart` for storing user-selected icons.

---

## 🏗️ Architecture

### Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, MaterialApp setup, onboarding flow orchestration |
| `lib/screens/home_screen.dart` | Central hub - manages state, routines, columns, and user interactions |
| `lib/services/routine_service.dart` | Default routines (Morning/Evening), task management |
| `lib/services/preferences_service.dart` | SharedPreferences wrapper for persistent storage |
| `lib/services/kiosk_service.dart` | Android screen pinning via MethodChannel |
| `lib/widgets/routine_drawer.dart` | Side menu with user preferences, dark mode toggle, language |

### State Management

The app uses **local state management** with `StatefulWidget`:
- `HomeScreen` is the central state holder
- State includes: current routine, columns, member data, dark mode, child mode, view mode
- Persistence via `SharedPreferences` (wrapped in `PreferencesService`)

### Responsive Design

The app adapts to screen size:
- **Mobile** (< 600px width): Tab view with one person per tab
- **Desktop/Tablet** (≥ 600px): Column view with all members side by side
- Users can override with a toggle in the menu

### Localization

- Uses Flutter's built-in localization (`flutter_localizations`)
- ARB files in `lib/l10n/`:
  - `app_en.arb` - English
  - `app_he.arb` - Hebrew (RTL supported)
- Access via `AppLocalizations.of(context)!.keyName`

---

## 🔑 Key Implementation Details

### 1. Avatar System

Members can have:
- **Icon avatars**: Material icons stored as `IconData.codePoint`
- **Custom images**: 
  - Web: Base64-encoded bytes in SharedPreferences
  - Mobile: File paths in app's documents directory

Storage keys in `PreferencesService`:
- `member_{id}_icon` - Icon codePoint
- `member_{id}_image_bytes` - Base64 image data
- `member_{id}_color` - Color as int value

### 2. Column/Task Data Model

```dart
class ColumnData {
  final String id;
  String name;
  Color color;
  List<Task> tasks;
  final GlobalKey<AnimatedListState> listKey;
}

class Task {
  final String id;
  final String text;
  bool isCompleted;
}
```

### 3. Dark Mode Behavior

- User can toggle via sun/moon switch in menu
- Evening Routine automatically sets dark mode
- State tracked in `main.dart` and passed to `HomeScreen`
- **Important**: `didChangeDependencies()` in `HomeScreen` tracks locale separately from theme to avoid re-initialization

### 4. Child Mode (Android)

When activated:
1. `KioskService.startLockTask()` - Calls native Android via MethodChannel
2. Android enters screen pinning + immersive fullscreen
3. Flutter's `PopScope` intercepts back button
4. To exit: User solves a number puzzle, then `KioskService.stopLockTask()`

Native implementation in `android/app/src/main/kotlin/.../MainActivity.kt`

### 5. Routine Loading

Default routines are defined in `RoutineService.initializeRoutines()`:
- Tasks are translated using current locale
- When language changes, `_updateLocalization()` in HomeScreen reloads tasks
- All tasks appear in ALL columns (not distributed)

---

## 🐛 Common Issues & Solutions

### Issue: Tasks reset when toggling dark mode

**Cause**: `didChangeDependencies()` was calling `_updateLocalization()` on theme changes
**Solution**: Track `_currentLocale` separately and only reload when locale actually changes

```dart
Locale? _currentLocale;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final newLocale = Localizations.localeOf(context);
  if (_currentLocale == null || _currentLocale != newLocale) {
    _currentLocale = newLocale;
    _updateLocalization();
  }
}
```

### Issue: Image upload not working on web

**Cause**: Web doesn't support `File` operations the same way as mobile
**Solution**: Use `Uint8List` bytes for web, store as Base64 in SharedPreferences

```dart
if (kIsWeb) {
  final bytes = await pickedFile.readAsBytes();
  // Store as base64, display with Image.memory(bytes)
} else {
  // Save to file system, store path
}
```

### Issue: ReorderableListView key error

**Cause**: Key was on inner widget instead of top-level item
**Solution**: Pass key to `EnhancedTaskCard` widget, not to internal `TweenAnimationBuilder`

```dart
EnhancedTaskCard(
  key: ValueKey(task.id),  // Must be on the outermost widget
  task: task,
  // ...
)
```

### Issue: Android build fails with tree shake error

**Cause**: Dynamic `IconData` usage in preferences
**Solution**: Add `--no-tree-shake-icons` flag

```bash
flutter build apk --release --no-tree-shake-icons
```

### Issue: setState() called during build

**Cause**: Calling `widget.onDarkModeChange()` during `_loadRoutine()` which triggers parent rebuild
**Solution**: Don't auto-switch theme during initialization, only on explicit routine selection

---

## 📂 File Organization

### Widgets Extracted from HomeScreen

The home_screen.dart was refactored to reduce size. Extracted widgets:

| Widget | File | Purpose |
|--------|------|---------|
| `RoutineTabView` | `widgets/home/routine_tab_view.dart` | Mobile tab layout |
| `RoutineColumnView` | `widgets/home/routine_column_view.dart` | Desktop column layout |
| `MemberAvatarWidget` | `widgets/home/member_avatar_widget.dart` | Avatar display (icon/image) |
| `RoutineColumnHeader` | `widgets/home/routine_column_header.dart` | Column header with avatar & buttons |
| `EnhancedTaskCard` | `widgets/home/enhanced_task_card.dart` | Task card with animation |

### Shared Dialogs

| Dialog | File | Purpose |
|--------|------|---------|
| `AvatarIconPickerDialog` | `widgets/dialogs/avatar_icon_picker_dialog.dart` | Icon selection + image upload |
| `AddMemberDialog` | `widgets/dialogs/add_member_dialog.dart` | Add member with avatar, name, color |
| `ColorPickerDialog` | `widgets/column_dialogs.dart` | Color selection grid |

---

## 🔄 Onboarding Flow

Managed in `main.dart` `_OnboardingFlow` widget:

1. **Language Selection** → Sets locale
2. **Household Setup** → Add family members with avatars/colors
3. **Tutorial** (7 pages) → Feature walkthrough

Navigation:
- Each screen accepts `onBack` callback for back navigation
- Progress tracked via `_currentStep` state
- `onCompleted` callback marks onboarding complete

---

## 🌍 Adding New Translations

1. Add keys to both `lib/l10n/app_en.arb` and `lib/l10n/app_he.arb`
2. Run `flutter gen-l10n` (or just `flutter run` which triggers it)
3. Access via `AppLocalizations.of(context)!.yourKey`

Example:
```json
// app_en.arb
{
  "yourKey": "Your text here",
  "@yourKey": {
    "description": "Description for translators"
  }
}
```

---

## 🧪 Testing on Devices

### Web (Any Device on Network)

```bash
# Start server
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Find your IP
# macOS: ifconfig | grep "inet " | grep -v 127.0.0.1
# Windows: ipconfig

# Access from device browser: http://<your-ip>:8080
```

### Android (USB or Wireless)

```bash
# List devices
adb devices

# Wireless debugging (Android 11+)
adb pair <ip>:<port>  # Use pairing code from device
adb connect <ip>:<port>

# Run on device
flutter run -d <device-id>

# Or install APK
adb install releases/routine-flow-v1.1.0.apk
```

---

## 📋 Key Dependencies

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Persistent storage |
| `flutter_colorpicker` | Color selection dialogs |
| `image_picker` | Photo upload from gallery |
| `path_provider` | App document directory access |
| `flutter_localizations` | i18n support |

---

## 🎨 UI Conventions

- **Colors**: Each member has a unique color, stored as int in preferences
- **Dark Mode**: Indigo-based dark theme
- **Animations**: Task completion uses `TweenAnimationBuilder` with scale/opacity
- **Icons**: Material Icons used throughout
- **Responsive**: 600px breakpoint for tab vs column view

---

## ⚠️ Important Notes for Agents

1. **Always use `--no-tree-shake-icons`** when building APK
2. **Image handling differs by platform** - check `kIsWeb` before using File operations
3. **HomeScreen is large** (~1200 lines) - prefer searching for specific methods
4. **Translations required** - add to BOTH .arb files when adding new user-facing text
5. **Test on web first** - faster iteration with `flutter run -d chrome`
6. **Kill old processes** before restarting: `pkill -9 dart; pkill -9 flutter`

---

## 📞 Platform-Specific Code

### Android (Kotlin)

Location: `android/app/src/main/kotlin/com/example/routine_flow_flutter/MainActivity.kt`

Handles:
- Screen pinning (`startLockTask`, `stopLockTask`)
- Immersive fullscreen mode

### iOS

No custom native code currently. Kiosk mode not supported on iOS.

---

*Last updated: December 2024*

