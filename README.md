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

---

## 🛠️ Development Setup

### 🍎 macOS Setup

#### 1. Install Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install --cask flutter

# Verify Flutter installation
flutter doctor

# Install OpenJDK 17 (required for Android builds)
brew install openjdk@17

# Set JAVA_HOME (add to ~/.zshrc for persistence)
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home")' >> ~/.zshrc
source ~/.zshrc
```

#### 2. Android SDK Setup (for building APKs)

```bash
# Install Android command line tools
brew install --cask android-commandlinetools

# Set ANDROID_HOME
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools

# Accept licenses
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install required SDK components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-34" "build-tools;34.0.0"
```

#### 3. Clone and Run

```bash
# Clone the repository
git clone <repository-url>
cd routine_flow_flutter

# Get dependencies
flutter pub get

# Run on web (accessible from other devices on same network)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Or run in Chrome browser
flutter run -d chrome
```

---

### 🪟 Windows Setup

#### 1. Install Prerequisites

**Option A: Using Chocolatey (Recommended)**
```powershell
# Install Chocolatey (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Flutter and Java
choco install flutter -y
choco install openjdk17 -y

# Restart terminal, then verify
flutter doctor
```

**Option B: Manual Installation**
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH environment variable
4. Download and install JDK 17 from https://adoptium.net/

#### 2. Set Environment Variables

```powershell
# Set JAVA_HOME (run as Administrator or set in System Properties > Environment Variables)
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot" /M

# Verify Java
java -version
```

#### 3. Android SDK Setup (for building APKs)

**Option A: Install Android Studio**
1. Download from https://developer.android.com/studio
2. Run Android Studio and complete the setup wizard
3. Go to SDK Manager and install:
   - Android SDK Platform 34
   - Android SDK Build-Tools 34.0.0

**Option B: Command Line Only**
```powershell
# Download command line tools from https://developer.android.com/studio#command-tools
# Extract to C:\Android\cmdline-tools\latest

# Set ANDROID_HOME
setx ANDROID_HOME "C:\Android" /M

# Accept licenses
C:\Android\cmdline-tools\latest\bin\sdkmanager.bat --licenses

# Install SDK components
C:\Android\cmdline-tools\latest\bin\sdkmanager.bat "platforms;android-34" "build-tools;34.0.0"
```

#### 4. Clone and Run

```powershell
# Clone the repository
git clone <repository-url>
cd routine_flow_flutter

# Get dependencies
flutter pub get

# Run on web (accessible from other devices on same network)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Or run in Chrome browser
flutter run -d chrome
```

---

## 🚀 Running the App

### Quick Start (Web Development)

```bash
# Install dependencies
flutter pub get

# Run on web server (accessible from any device on your network)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

Then open `http://<your-ip>:8080` on any device (phone, tablet, or another computer).

### Run Commands

| Command | Description |
|---------|-------------|
| `flutter run -d chrome` | Run in Chrome browser |
| `flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0` | Run on web server (network accessible) |
| `flutter run -d <device-id>` | Run on connected Android/iOS device |
| `flutter run -d macos` | Run as macOS desktop app |
| `flutter run -d windows` | Run as Windows desktop app |

### Build Commands

```bash
# Build release APK (Android)
flutter build apk --release --no-tree-shake-icons

# Build for web
flutter build web

# Build for macOS
flutter build macos

# Build for Windows
flutter build windows
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point & onboarding flow
├── screens/                  # Screen widgets
│   ├── home_screen.dart      # Main routine view (central hub)
│   ├── manage_household_screen.dart
│   ├── add_routine_screen.dart
│   ├── edit_routine_screen.dart
│   └── onboarding/           # First-time setup screens
│       ├── language_selection_screen.dart
│       ├── household_setup_screen.dart
│       └── tutorial_screen.dart
├── widgets/                  # Reusable widgets
│   ├── home/                 # Home screen components
│   │   ├── routine_tab_view.dart
│   │   ├── routine_column_view.dart
│   │   ├── member_avatar_widget.dart
│   │   ├── routine_column_header.dart
│   │   └── enhanced_task_card.dart
│   ├── dialogs/              # Shared dialog widgets
│   │   ├── avatar_icon_picker_dialog.dart
│   │   └── add_member_dialog.dart
│   ├── routine_drawer.dart   # Side menu
│   └── ...
├── services/                 # Business logic
│   ├── routine_service.dart      # Routine data management
│   ├── preferences_service.dart  # SharedPreferences storage
│   └── kiosk_service.dart        # Android screen pinning
├── models/                   # Data models
│   ├── task.dart
│   └── column_data.dart
├── utils/                    # Utilities
│   └── routine_animation.dart
└── l10n/                     # Localization files
    ├── app_en.arb            # English translations
    └── app_he.arb            # Hebrew translations
```

---

## 🌐 Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Full support (including kiosk mode) |
| iOS      | ✅ Works (no kiosk mode) |
| Web      | ✅ Works (no kiosk mode) |
| macOS    | ✅ Works |
| Windows  | ✅ Works |
| Linux    | ✅ Works |

---

## 🔧 Troubleshooting

### Common Issues

**"Unable to locate a Java Runtime"**
```bash
# macOS
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Windows (PowerShell)
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot"
```

**"Android SDK licenses not accepted"**
```bash
# macOS
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Windows
C:\Android\cmdline-tools\latest\bin\sdkmanager.bat --licenses
```

**"flutter: command not found"**
- Ensure Flutter is in your PATH
- Restart your terminal after installation
- Run `flutter doctor` to check setup

**Port 8080 already in use**
```bash
# Use a different port
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0

# Or kill the process using port 8080
# macOS/Linux
lsof -ti:8080 | xargs kill -9
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

---

## 📄 License

This project is for personal/family use.

---

Made with ❤️ using Flutter
