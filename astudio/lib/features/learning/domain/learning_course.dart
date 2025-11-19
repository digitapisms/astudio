import 'package:equatable/equatable.dart';

import 'learning_lesson.dart';
import 'learning_progress.dart';

enum CourseLevel { beginner, intermediate, advanced }

extension CourseLevelX on CourseLevel {
  static CourseLevel fromString(String value) {
    return CourseLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => CourseLevel.beginner,
    );
  }

  String get label {
    switch (this) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
    }
  }
}

class LearningCourse extends Equatable {
  const LearningCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.durationMinutes,
    this.coverImageUrl,
    this.tags = const [],
    this.lessons = const [],
    this.progress,
  });

  final String id;
  final String title;
  final String? description;
  final CourseLevel level;
  final bool isPublished;
  final int? durationMinutes;
  final String? coverImageUrl;
  final List<String> tags;
  final List<LearningLesson> lessons;
  final LearningProgress? progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => progress?.isCompleted ?? false;

  factory LearningCourse.fromJson(Map<String, dynamic> json) {
    return LearningCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      level: CourseLevelX.fromString(
        json['level'] as String? ?? 'beginner',
      ),
      isPublished: json['is_published'] as bool? ?? false,
      durationMinutes: json['duration_minutes'] as int?,
      coverImageUrl: json['cover_image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LearningLesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      progress: json['progress'] != null
          ? LearningProgress.fromJson(
              json['progress'] as Map<String, dynamic>,
            )
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, level, isPublished, durationMinutes, tags, progress];
}

