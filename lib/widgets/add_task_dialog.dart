import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String) onAdd;

  const AddTaskDialog({super.key, required this.onAdd});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _textController = TextEditingController();
  bool _showEmojiPicker = false;

  final List<String> _quickEmojis = [
    // Morning Routine
    '🌅', // Wake up
    '🦷', // Brush teeth
    '👕', // Get dressed
    '🍳', // Breakfast
    '🥛', // Milk
    '🍎', // Apple
    '🍌', // Banana
    '🍞', // Bread
    '🎒', // School bag
    '🚌', // School bus
    
    // School Activities
    '📚', // Books
    '✏️', // Pencil
    '🎨', // Art
    '🎵', // Music
    '⚽', // Sports
    '🎮', // Games
    '🎲', // Board games
    '🎪', // Fun activities
    '🎯', // Target/Goals
    '🏆', // Achievement
    
    // After School & Evening
    '🍪', // Snack
    '🍦', // Ice cream
    '🛁', // Bath
    '🦖', // Toys/Dinosaurs
    '🐶', // Pets
    '🌙', // Night time
    '⭐', // Stars
    '🌠', // Shooting star
    '🌜', // Moon
    '😴', // Sleep
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    // If the text field is empty or no selection, append the emoji at the end
    if (text.isEmpty || selection.start < 0) {
      _textController.text = text + emoji;
      _textController.selection = TextSelection.collapsed(offset: text.length + emoji.length);
      return;
    }

    // Otherwise, insert at the current cursor position
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.addNewTask),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickEmojis.map((emoji) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => _insertEmoji(emoji),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: l10n.enterTaskText,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                  },
                ),
              ),
              maxLines: 3,
            ),
            if (_showEmojiPicker) Container(
              height: 250,
              margin: const EdgeInsets.only(top: 8),
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _insertEmoji(emoji.emoji);
                  setState(() {
                    _showEmojiPicker = false;
                  });
                },
                config: Config(
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  initCategory: Category.RECENT,
                  bgColor: Theme.of(context).scaffoldBackgroundColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  iconColorSelected: Theme.of(context).primaryColor,
                  iconColor: Colors.grey,
                  backspaceColor: Theme.of(context).primaryColor,
                  noRecents: Text(
                    l10n.noRecentEmojis,
                    style: const TextStyle(fontSize: 20),
                  ),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  categoryIcons: const CategoryIcons(),
                  buttonMode: ButtonMode.MATERIAL,
                  checkPlatformCompatibility: true,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_textController.text.isNotEmpty) {
              widget.onAdd(_textController.text);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
} 