import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Service to handle kiosk mode (screen pinning) on Android
/// This prevents children from leaving the app when child mode is active
class KioskService {
  static const MethodChannel _channel = MethodChannel('com.routineflow/kiosk');

  /// Check if we're running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Start screen pinning (kiosk mode)
  /// This will show a system dialog asking the user to confirm
  static Future<bool> startScreenPinning() async {
    if (!isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('startScreenPinning');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start screen pinning: ${e.message}');
      return false;
    }
  }

  /// Stop screen pinning
  static Future<bool> stopScreenPinning() async {
    if (!isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('stopScreenPinning');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to stop screen pinning: ${e.message}');
      return false;
    }
  }

  /// Check if screen is currently pinned
  static Future<bool> isScreenPinned() async {
    if (!isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isScreenPinned');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check screen pinning status: ${e.message}');
      return false;
    }
  }

  /// Enter immersive fullscreen mode (hides status bar and navigation)
  static Future<void> enterImmersiveMode() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('enterImmersiveMode');
    } on PlatformException catch (e) {
      print('Failed to enter immersive mode: ${e.message}');
    }
  }

  /// Exit immersive mode (show status bar and navigation)
  static Future<void> exitImmersiveMode() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('exitImmersiveMode');
    } on PlatformException catch (e) {
      print('Failed to exit immersive mode: ${e.message}');
    }
  }
}

