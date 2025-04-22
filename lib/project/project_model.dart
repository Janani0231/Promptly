import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'project_task_model.dart';

class Project {
  final String id;
  final String title;
  final String userId;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final List<String>
      taskIds; // References to tasks associated with this project

  Project({
    String? id,
    required this.title,
    required this.userId,
    this.description = '',
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? taskIds,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now(),
        this.dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7)),
        this.taskIds = taskIds ?? [];

  Project copyWith({
    String? id,
    String? title,
    String? userId,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? taskIds,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      taskIds: taskIds ?? this.taskIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'task_ids': taskIds,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      userId: json['user_id'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      taskIds:
          (json['task_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  double getProgress(List<ProjectTask> tasks) {
    if (tasks.isEmpty) return 0.0;

    int completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }
}
