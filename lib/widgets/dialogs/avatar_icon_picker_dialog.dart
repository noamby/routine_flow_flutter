import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class AvatarIconPickerDialog extends StatelessWidget {
  final Color memberColor;
  final IconData? currentIcon;
  final bool hasCustomImage;
  final Function(IconData) onIconSelected;
  final Function(Uint8List imageBytes) onImageSelected;

  const AvatarIconPickerDialog({
    super.key,
    required this.memberColor,
    this.currentIcon,
    this.hasCustomImage = false,
    required this.onIconSelected,
    required this.onImageSelected,
  });

  static const List<IconData> availableIcons = [
    Icons.person,
    Icons.face,
    Icons.child_care,
    Icons.boy,
    Icons.girl,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
    Icons.mood,
    Icons.emoji_emotions,
    Icons.pets,
    Icons.favorite,
    Icons.star,
    Icons.brightness_5,
    Icons.wb_sunny,
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_baseball,
    Icons.sports_football,
    Icons.music_note,
    Icons.palette,
    Icons.brush,
    Icons.draw,
    Icons.cake,
    Icons.toys,
    Icons.rocket_launch,
    Icons.beach_access,
  ];

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      onImageSelected(bytes);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Choose Avatar'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = availableIcons[index];
                  final isSelected = !hasCustomImage &&
                      (currentIcon == icon || (currentIcon == null && icon == Icons.person));

                  return InkWell(
                    onTap: () {
                      onIconSelected(icon);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? memberColor.withOpacity(0.3)
                            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? memberColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: memberColor,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(context),
          icon: const Icon(Icons.photo_library),
          label: const Text('Upload Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

