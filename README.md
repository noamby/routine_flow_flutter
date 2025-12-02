# Routine Flow 🌅🌙

A beautiful Flutter app to help families organize daily routines for children. Create morning and evening task lists, track progress, and keep kids engaged with fun animations!

## ✨ Features

- **Morning & Evening Routines** - Built-in routines with customizable tasks
- **Multiple Family Members** - Each child gets their own task column with personalized colors and avatars
- **Custom Avatars** - Choose from icons or upload your own photos
- **Child Mode** 🔒 - Lock the app so kids can only check tasks (with Android screen pinning support)
- **Dark/Light Mode** - Beautiful sun/moon toggle in menu, auto-switches for evening routines!
- **Color Picker in Child Mode** - Kids can change their column colors for fun
- **Multi-Language** - English and Hebrew support with full translations
- **Beautiful Animations** - 5 different animation styles for task lists
- **Flexible Views** - Tab view (one person) or column view (everyone side by side)
- **Interactive Tutorial** - 7-page guide accessible anytime from the menu
- **Responsive Design** - Works on phones, tablets, and web

## 📱 Quick Install (Android)

### Download the APK

1. Download the latest APK: **[routine-flow-v1.1.0.apk](releases/routine-flow-v1.1.0.apk)** (23.6 MB)
2. Transfer to your Android device
3. Open the APK file and tap "Install"
   - You may need to enable "Install from unknown sources" in Settings

### Alternative: Direct ADB Install

If you have ADB set up:
```bash
adb install releases/routine-flow-v1.1.0.apk
```

### Previous Versions

- [v1.0.0](releases/routine-flow-v1.0.0.apk) - Initial release

## 🔒 Child Mode (Android)

When you activate Child Mode on Android:
- The app goes **fullscreen** (hides status bar and navigation)
- **Screen pinning** is activated (Android will ask to confirm the first time)
- Children **cannot exit** the app or press the back button
- To exit, tap the child mode button and solve a simple number puzzle

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK (3.29+)
- Dart SDK
- For Android builds: JDK 17 + Android SDK

### Run the App

```bash
# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on connected Android device
flutter run -d <device-id>

# Build release APK
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
flutter build apk --release --no-tree-shake-icons
```

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── home_screen.dart      # Main routine view
│   ├── manage_household_screen.dart
│   ├── add_routine_screen.dart
│   ├── edit_routine_screen.dart
│   └── onboarding/           # First-time setup screens
├── widgets/                  # Reusable widgets
│   ├── home/                 # Home screen components
│   ├── dialogs/              # Dialog widgets
│   └── ...
├── services/                 # Business logic
│   ├── routine_service.dart
│   ├── preferences_service.dart
│   └── kiosk_service.dart    # Android screen pinning
├── models/                   # Data models
├── utils/                    # Utilities
└── l10n/                     # Localization files
    ├── app_en.arb            # English
    └── app_he.arb            # Hebrew
```

## 🌐 Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Full support (including kiosk mode) |
| iOS      | ✅ Works (no kiosk mode) |
| Web      | ✅ Works (no kiosk mode) |
| macOS    | ✅ Works |
| Windows  | ✅ Works |
| Linux    | ✅ Works |

## 📄 License

This project is for personal/family use.

---

Made with ❤️ using Flutter
