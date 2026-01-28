import 'package:characters/characters.dart';

class Task {
  String text;
  bool isDone;
  String? icon; // Optional emoji icon for the task

  Task({required this.text, this.isDone = false, this.icon});

  // Serialization for persistence
  Map<String, dynamic> toJson() => {
    'text': text,
    'isDone': isDone,
    'icon': icon,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    text: json['text'] as String,
    isDone: json['isDone'] as bool? ?? false,
    icon: json['icon'] as String?,
  );

  /// Extracts the first emoji from the text if no explicit icon is set
  String? get displayIcon {
    if (icon != null && icon!.isNotEmpty) return icon;
    
    // Try to extract emoji from the beginning of text
    if (text.isNotEmpty) {
      final chars = text.characters;
      if (chars.isNotEmpty) {
        final firstChar = chars.first;
        // Check if it's likely an emoji (basic heuristic: non-ASCII and not a regular letter)
        if (_isEmoji(firstChar)) {
          return firstChar;
        }
      }
    }
    return null;
  }

  /// Returns the text without the leading emoji (to avoid duplication when icon is shown separately)
  String get displayText {
    if (displayIcon != null && text.isNotEmpty) {
      final chars = text.characters;
      if (chars.isNotEmpty && _isEmoji(chars.first)) {
        // Remove the first character (emoji) and trim leading whitespace
        return chars.skip(1).toString().trimLeft();
      }
    }
    return text;
  }

  /// Improved emoji detection - checks for actual emoji Unicode ranges
  static bool _isEmoji(String char) {
    if (char.isEmpty) return false;
    
    // Get the first rune (Unicode code point)
    final rune = char.runes.first;
    
    // Check various emoji Unicode ranges
    return 
        // Emoticons
        (rune >= 0x1F600 && rune <= 0x1F64F) ||
        // Miscellaneous Symbols and Pictographs
        (rune >= 0x1F300 && rune <= 0x1F5FF) ||
        // Transport and Map Symbols
        (rune >= 0x1F680 && rune <= 0x1F6FF) ||
        // Supplemental Symbols and Pictographs
        (rune >= 0x1F900 && rune <= 0x1F9FF) ||
        // Symbols and Pictographs Extended-A
        (rune >= 0x1FA00 && rune <= 0x1FAFF) ||
        // Dingbats
        (rune >= 0x2700 && rune <= 0x27BF) ||
        // Miscellaneous Symbols
        (rune >= 0x2600 && rune <= 0x26FF) ||
        // Regional Indicator Symbols (flags)
        (rune >= 0x1F1E0 && rune <= 0x1F1FF) ||
        // Enclosed Alphanumeric Supplement (circled numbers, etc.)
        (rune >= 0x1F100 && rune <= 0x1F1FF) ||
        // Playing Cards, Mahjong Tiles
        (rune >= 0x1F000 && rune <= 0x1F0FF) ||
        // Arrows, Math symbols that are often used as emoji
        (rune >= 0x2190 && rune <= 0x21FF) ||
        // Food & Drink, Animals, Nature (common emoji area)
        (rune >= 0x1F400 && rune <= 0x1F4FF) ||
        // Variation selectors don't count, but characters with them might be emoji
        // Check for common single-character emoji
        (rune == 0x2764) || // ❤️ Red Heart
        (rune == 0x2B50) || // ⭐ Star
        (rune == 0x2728) || // ✨ Sparkles
        (rune == 0x2705) || // ✅ Check mark
        (rune == 0x274C) || // ❌ Cross mark
        (rune == 0x2B55) || // ⭕ Circle
        (rune == 0x203C) || // ‼️ Double exclamation
        (rune == 0x2049) || // ⁉️ Exclamation question
        (rune == 0x00A9) || // © Copyright
        (rune == 0x00AE);   // ® Registered
  }

  /// Returns ALL emojis found in the task text
  List<String> get allEmojis {
    final emojis = <String>[];
    
    // First add the explicit icon if set
    if (icon != null && icon!.isNotEmpty) {
      emojis.add(icon!);
    }
    
    // Then extract all emojis from the text
    if (text.isNotEmpty) {
      for (final char in text.characters) {
        if (_isEmoji(char) && !emojis.contains(char)) {
          emojis.add(char);
        }
      }
    }
    
    return emojis;
  }
} 