import 'package:flutter/material.dart';
import '../../models/column_data.dart';

class RoutineTabView extends StatelessWidget {
  final TabController tabController;
  final List<ColumnData> columns;
  final Widget Function(ColumnData) buildColumn;
  final Widget Function(ColumnData, bool) buildAvatar;
  final String Function(ColumnData) getMemberName;

  const RoutineTabView({
    super.key,
    required this.tabController,
    required this.columns,
    required this.buildColumn,
    required this.buildAvatar,
    required this.getMemberName,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: columns.map((column) {
            final memberName = getMemberName(column);

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar in tab
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: buildAvatar(column, isDarkMode),
                  ),
                  const SizedBox(width: 8),
                  Text(memberName),
                ],
              ),
            );
          }).toList(),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: columns.map((column) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildColumn(column),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

