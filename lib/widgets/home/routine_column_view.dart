import 'package:flutter/material.dart';
import '../../models/column_data.dart';

class RoutineColumnView extends StatelessWidget {
  final List<ColumnData> columns;
  final Widget Function(ColumnData) buildColumn;

  const RoutineColumnView({
    super.key,
    required this.columns,
    required this.buildColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: columns.map((column) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: buildColumn(column),
          ),
        )).toList(),
      ),
    );
  }
}

