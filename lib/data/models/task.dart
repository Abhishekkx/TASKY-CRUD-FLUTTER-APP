import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final int? id;
  final String title;
  final String description;
  final bool status;
  final DateTime createdDate;
  final int priority;
  final DateTime? dueDate;  // New field for reminder time

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdDate,
    required this.priority,
    this.dueDate,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? status,
    DateTime? createdDate,
    int? priority,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      status: (map['status'] as int) == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
      priority: map['priority'] as int,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': status,
      'createdDate': createdDate.toIso8601String(),
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] ?? 'No description',
      status: json['completed'] ?? false,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : DateTime.now(),
      priority: json['priority'] ?? 1,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, createdDate, priority, dueDate];
}