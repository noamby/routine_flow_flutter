import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service for playing celebration sounds
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _player;
  final Random _random = Random();

  /// Sound files for when a column is completed (path relative to assets/)
  static const List<String> _completionSounds = [
    'sounds/finished/brass-fanfare-with-timpani-and-winchimes-reverberated-146260.mp3',
    'sounds/finished/goodresult-82807.mp3',
    'sounds/finished/orchestral-win-331233.mp3',
    'sounds/finished/spin-complete-295086.mp3',
    'sounds/finished/success-fanfare-trumpets-6185.mp3',
    'sounds/finished/tadaa-47995.mp3',
  ];

  /// Get or create the audio player
  AudioPlayer _getPlayer() {
    if (_player == null) {
      _player = AudioPlayer();
      // Set release mode to stop so we can reuse the player
      _player!.setReleaseMode(ReleaseMode.stop);
    }
    return _player!;
  }

  /// Play a random celebration sound for completing a column
  Future<void> playCompletionSound() async {
    try {
      final soundFile = _completionSounds[_random.nextInt(_completionSounds.length)];
      final player = _getPlayer();
      await player.stop();
      await player.play(AssetSource(soundFile));
      debugPrint('AudioService: Playing completion sound: $soundFile');
    } catch (e) {
      debugPrint('AudioService: Error playing completion sound: $e');
    }
  }

  /// Stop any currently playing sound
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('AudioService: Error stopping sound: $e');
    }
  }

  /// Dispose of the audio player
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
