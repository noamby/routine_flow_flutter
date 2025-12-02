import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import '../../models/column_data.dart';

class MemberAvatarWidget extends StatelessWidget {
  final ColumnData column;
  final bool isDarkMode;
  final Map<String, IconData> memberIcons;
  final Map<String, String> memberImages;
  final Map<String, Uint8List> memberImageBytes;
  final bool isChildMode;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const MemberAvatarWidget({
    super.key,
    required this.column,
    required this.isDarkMode,
    required this.memberIcons,
    required this.memberImages,
    required this.memberImageBytes,
    this.isChildMode = false,
    this.onTap,
    this.showEditBadge = true,
  });

  Widget _buildAvatarContent() {
    // Check if custom image exists
    if (kIsWeb && memberImageBytes.containsKey(column.id)) {
      // For web: use bytes
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 20,
        backgroundImage: MemoryImage(memberImageBytes[column.id]!),
      );
    } else if (!kIsWeb && memberImages.containsKey(column.id)) {
      // For mobile: use file path
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 20,
        backgroundImage: FileImage(File(memberImages[column.id]!)),
      );
    }

    // Otherwise show icon
    return CircleAvatar(
      backgroundColor: column.color.withOpacity(0.2),
      radius: 20,
      child: Icon(
        memberIcons[column.id] ?? Icons.person,
        color: isDarkMode ? Colors.white : column.color,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isChildMode && showEditBadge && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            _buildAvatarContent(),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildAvatarContent();
  }
}

