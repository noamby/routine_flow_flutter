import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/column_data.dart';

class AddColumnDialog extends StatelessWidget {
  final Function(String) onAdd;

  const AddColumnDialog({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    return AlertDialog(
      title: Text(l10n.addNewMember),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.enterMemberName,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              onAdd(controller.text);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

class EditColumnNameDialog extends StatelessWidget {
  final ColumnData column;
  final Function(String) onSave;

  const EditColumnNameDialog({
    super.key,
    required this.column,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: column.name);

    return AlertDialog(
      title: Text(l10n.editName),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.enterMemberName,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              onSave(controller.text);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class ColorPickerDialog extends StatelessWidget {
  final ColumnData? column;
  final Color? initialColor;
  final Function(Color) onColorChanged;

  const ColorPickerDialog({
    super.key,
    this.column,
    this.initialColor,
    required this.onColorChanged,
  }) : assert(column != null || initialColor != null, 'Either column or initialColor must be provided');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = column?.color ?? initialColor!;

    return AlertDialog(
      title: Text(l10n.pickColor),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: color,
          onColorChanged: onColorChanged,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

class ManageColumnsDialog extends StatelessWidget {
  final List<ColumnData> columns;
  final Function(int) onDelete;
  final Function(String) onEdit;
  final VoidCallback onAddNew;

  const ManageColumnsDialog({
    super.key,
    required this.columns,
    required this.onDelete,
    required this.onEdit,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.manageHousehold),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: columns.length,
          itemBuilder: (context, index) {
            final column = columns[index];
            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: column.color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(column.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (columns.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        onDelete(index);
                        Navigator.pop(context);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit(column.id);
                    },
                    tooltip: l10n.editNameTooltip,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onAddNew();
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addNewMember),
        ),
      ],
    );
  }
}