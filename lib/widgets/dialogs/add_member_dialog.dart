import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'avatar_icon_picker_dialog.dart';

/// Data class to hold member information
class MemberData {
  final String name;
  final IconData icon;
  final Uint8List? imageBytes;
  final Color color;

  MemberData({
    required this.name,
    required this.icon,
    this.imageBytes,
    required this.color,
  });
}

/// Reusable dialog for adding a new family member with avatar, name, and color
class AddMemberDialog extends StatefulWidget {
  final Function(MemberData) onAdd;

  const AddMemberDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  IconData _selectedIcon = Icons.person;
  Uint8List? _selectedImageBytes;
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pickColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(l10n.addNewMember),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar picker
            GestureDetector(
              onTap: () => _showAvatarPicker(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _selectedColor.withOpacity(0.2),
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : null,
                    child: _selectedImageBytes == null
                        ? Icon(
                            _selectedIcon,
                            size: 50,
                            color: _selectedColor,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change avatar',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Name input
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.enterMemberName,
                hintText: l10n.enterMemberName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),

            // Color picker button
            Text(
              l10n.pickColor,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showColorPicker(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedColor, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tap to change color',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.palette,
                      color: _selectedColor,
                      size: 20,
                    ),
                  ],
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
            if (_nameController.text.isNotEmpty) {
              widget.onAdd(MemberData(
                name: _nameController.text,
                icon: _selectedIcon,
                imageBytes: _selectedImageBytes,
                color: _selectedColor,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) => AvatarIconPickerDialog(
        memberColor: _selectedColor,
        currentIcon: _selectedIcon,
        hasCustomImage: _selectedImageBytes != null,
        onIconSelected: (icon) {
          setState(() {
            _selectedIcon = icon;
            _selectedImageBytes = null;
          });
        },
        onImageSelected: (bytes) {
          setState(() {
            _selectedImageBytes = bytes;
          });
        },
      ),
    );
  }
}

