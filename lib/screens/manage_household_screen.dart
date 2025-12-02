import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/column_data.dart';
import '../services/preferences_service.dart';
import '../widgets/column_dialogs.dart';
import '../widgets/dialogs/avatar_icon_picker_dialog.dart';
import '../widgets/dialogs/add_member_dialog.dart';

class ManageHouseholdScreen extends StatefulWidget {
  final List<ColumnData> columns;
  final List<String> memberNames;
  final Map<String, IconData> memberIcons;
  final Map<String, String> memberImages;
  final Map<String, Uint8List> memberImageBytes;
  final Function(List<String>, List<ColumnData>, Map<String, IconData>, Map<String, String>, Map<String, Uint8List>) onSave;

  const ManageHouseholdScreen({
    super.key,
    required this.columns,
    required this.memberNames,
    required this.memberIcons,
    required this.memberImages,
    required this.memberImageBytes,
    required this.onSave,
  });

  @override
  State<ManageHouseholdScreen> createState() => _ManageHouseholdScreenState();
}

class _ManageHouseholdScreenState extends State<ManageHouseholdScreen> {
  late List<ColumnData> _columns;
  late List<String> _memberNames;
  late Map<String, IconData> _memberIcons;
  late Map<String, String> _memberImages;
  late Map<String, Uint8List> _memberImageBytes;

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
    _memberNames = List.from(widget.memberNames);
    _memberIcons = Map.from(widget.memberIcons);
    _memberImages = Map.from(widget.memberImages);
    _memberImageBytes = Map.from(widget.memberImageBytes);
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        onAdd: (memberData) {
          setState(() {
            final newId = 'member_${DateTime.now().millisecondsSinceEpoch}';
            _memberNames.add(memberData.name);
            _columns.add(ColumnData(
              id: newId,
              name: "${memberData.name}'s Tasks",
              color: memberData.color,
              tasks: [],
              listKey: GlobalKey<AnimatedListState>(),
            ));
            _memberIcons[newId] = memberData.icon;
            if (memberData.imageBytes != null) {
              _memberImageBytes[newId] = memberData.imageBytes!;
            }
          });
        },
      ),
    );
  }

  void _editMemberName(int index) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _memberNames[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNameTooltip),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.enterMemberName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _memberNames[index] = controller.text;
                  _columns[index] = ColumnData(
                    id: _columns[index].id,
                    name: "${controller.text}'s Tasks",
                    color: _columns[index].color,
                    tasks: _columns[index].tasks,
                    listKey: _columns[index].listKey,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _editMemberIcon(int index) {
    final columnId = _columns[index].id;
    final hasCustomImage = _memberImages.containsKey(columnId) || _memberImageBytes.containsKey(columnId);

    showDialog(
      context: context,
      builder: (context) => AvatarIconPickerDialog(
        memberColor: _columns[index].color,
        currentIcon: _memberIcons[columnId],
        hasCustomImage: hasCustomImage,
        onIconSelected: (icon) {
          setState(() {
            _memberIcons[columnId] = icon;
            // Clear custom image if icon selected
            _memberImages.remove(columnId);
            _memberImageBytes.remove(columnId);
          });
        },
        onImageSelected: (bytes) {
          setState(() {
            _memberImageBytes[columnId] = bytes;
            _memberImages.remove(columnId); // Clear file path if using bytes
          });
        },
      ),
    );
  }

  void _editMemberColor(int index) {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: _columns[index].color,
        onColorChanged: (color) {
          setState(() {
            _columns[index] = ColumnData(
              id: _columns[index].id,
              name: _columns[index].name,
              color: color,
              tasks: _columns[index].tasks,
              listKey: _columns[index].listKey,
            );
          });
        },
      ),
    );
  }

  void _deleteMember(int index) {
    final l10n = AppLocalizations.of(context)!;

    if (_columns.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotDeleteLastMember ?? 'Cannot delete the last member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete ?? 'Confirm Delete'),
        content: Text('Are you sure you want to remove ${_memberNames[index]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final columnId = _columns[index].id;
              setState(() {
                _memberNames.removeAt(index);
                _memberIcons.remove(columnId);
                _memberImages.remove(columnId);
                _memberImageBytes.remove(columnId);
                _columns.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text(l10n.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(int index) {
    final column = _columns[index];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if custom image exists
    if (kIsWeb && _memberImageBytes.containsKey(column.id)) {
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 28,
        backgroundImage: MemoryImage(_memberImageBytes[column.id]!),
      );
    } else if (!kIsWeb && _memberImages.containsKey(column.id)) {
      return CircleAvatar(
        backgroundColor: column.color.withOpacity(0.2),
        radius: 28,
        backgroundImage: FileImage(File(_memberImages[column.id]!)),
      );
    }

    return CircleAvatar(
      backgroundColor: column.color.withOpacity(0.2),
      radius: 28,
      child: Icon(
        _memberIcons[column.id] ?? Icons.person,
        color: isDarkMode ? Colors.white : column.color,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode ? [
              Colors.grey.shade900,
              Colors.black,
              Colors.grey.shade800,
            ] : [
              Colors.green.shade50,
              Colors.white,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.green.shade600,
                        ),
                        onPressed: () {
                          widget.onSave(
                            _memberNames,
                            _columns,
                            _memberIcons,
                            _memberImages,
                            _memberImageBytes,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.manageHousehold,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.green.shade600,
                        ),
                        onPressed: _addMember,
                      ),
                    ),
                  ],
                ),
              ),

              // Member list
              Expanded(
                child: _columns.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noFamilyMembersAddedYet,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _columns.length,
                        itemBuilder: (context, index) {
                          final column = _columns[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar with edit badge
                                  GestureDetector(
                                    onTap: () => _editMemberIcon(index),
                                    child: Stack(
                                      children: [
                                        _buildAvatarWidget(index),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
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
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Name and color indicator
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _memberNames[index],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: column.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${column.tasks.length} tasks',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.palette,
                                          color: column.color,
                                        ),
                                        onPressed: () => _editMemberColor(index),
                                        tooltip: l10n.editColorTooltip,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                        ),
                                        onPressed: () => _editMemberName(index),
                                        tooltip: l10n.editNameTooltip,
                                      ),
                                      if (_columns.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteMember(index),
                                          tooltip: l10n.delete ?? 'Delete',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
