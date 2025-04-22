class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final String userId;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.userId,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? userId,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 