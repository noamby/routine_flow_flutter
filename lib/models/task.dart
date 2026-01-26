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

  /// Basic emoji detection heuristic
  static bool _isEmoji(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnits.first;
    // Emoji ranges: most emojis are above standard ASCII
    // This includes emoticons, symbols, and pictographs
    return codeUnit > 127 || 
           (char.length > 1 && char.codeUnits.length >= 2);
  }
} 