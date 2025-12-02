import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:typed_data';
import '../../models/column_data.dart';
import 'member_avatar_widget.dart';

class RoutineColumnHeader extends StatelessWidget {
  final ColumnData column;
  final bool isDarkMode;
  final bool isChildMode;
  final Map<String, IconData> memberIcons;
  final Map<String, String> memberImages;
  final Map<String, Uint8List> memberImageBytes;
  final VoidCallback onAvatarTap;
  final VoidCallback onColorTap;
  final VoidCallback onEditNameTap;
  final VoidCallback onAddTaskTap;

  const RoutineColumnHeader({
    super.key,
    required this.column,
    required this.isDarkMode,
    required this.isChildMode,
    required this.memberIcons,
    required this.memberImages,
    required this.memberImageBytes,
    required this.onAvatarTap,
    required this.onColorTap,
    required this.onEditNameTap,
    required this.onAddTaskTap,
  });

  Widget _buildColumnActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 16,
            color: color,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? column.color.withOpacity(0.3)
            : column.color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          MemberAvatarWidget(
            column: column,
            isDarkMode: isDarkMode,
            memberIcons: memberIcons,
            memberImages: memberImages,
            memberImageBytes: memberImageBytes,
            isChildMode: isChildMode,
            onTap: onAvatarTap,
            showEditBadge: !isChildMode,
          ),
          const SizedBox(width: 12),
          // Column title
          Expanded(
            child: Text(
              column.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ),
          // Action buttons
          if (!isChildMode) ...[
            _buildColumnActionButton(
              icon: Icons.palette,
              color: column.color,
              onPressed: onColorTap,
              tooltip: l10n.editColorTooltip,
            ),
            const SizedBox(width: 4),
            _buildColumnActionButton(
              icon: Icons.edit,
              color: Colors.blue,
              onPressed: onEditNameTap,
              tooltip: l10n.editNameTooltip,
            ),
            const SizedBox(width: 4),
            _buildColumnActionButton(
              icon: Icons.add,
              color: Colors.green,
              onPressed: onAddTaskTap,
              tooltip: l10n.addTaskTooltip,
            ),
          ],
        ],
      ),
    );
  }
}

