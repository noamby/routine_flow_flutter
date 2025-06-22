import 'package:flutter/material.dart';
import 'task.dart';

class ColumnData {
  final String id;
  String name;
  Color color;
  final List<Task> tasks;
  final GlobalKey<AnimatedListState> listKey;

  ColumnData({
    required this.id,
    required this.name,
    required this.color,
    required this.tasks,
    required this.listKey,
  });
} 