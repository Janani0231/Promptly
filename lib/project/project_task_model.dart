import 'package:uuid/uuid.dart';

class ProjectTask {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String projectId;
  final bool isCompleted;
  final DateTime createdAt;

  ProjectTask({
    String? id,
    required this.title,
    this.description = '',
    required this.userId,
    required this.projectId,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now();

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? projectId,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'user_id': userId,
      'project_id': projectId,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
