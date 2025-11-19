import 'package:equatable/equatable.dart';

class LearningProgress extends Equatable {
  const LearningProgress({
    required this.id,
    required this.profileId,
    required this.courseId,
    required this.status,
    required this.completedLessons,
    this.lastLessonId,
    this.completedAt,
    this.lastAccessedAt,
  });

  final String id;
  final String profileId;
  final String courseId;
  final String status;
  final List<String> completedLessons;
  final String? lastLessonId;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  bool get isCompleted => status == 'completed';

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      courseId: json['course_id'] as String,
      status: json['status'] as String? ?? 'in_progress',
      completedLessons: (json['completed_lessons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastLessonId: json['last_lesson_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.tryParse(json['last_accessed_at'] as String)
          : null,
    );
  }

  LearningProgress copyWith({
    List<String>? completedLessons,
    String? status,
    String? lastLessonId,
  }) {
    return LearningProgress(
      id: id,
      profileId: profileId,
      courseId: courseId,
      status: status ?? this.status,
      completedLessons: completedLessons ?? this.completedLessons,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      completedAt: completedAt,
      lastAccessedAt: lastAccessedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, courseId, profileId, status, completedLessons, lastLessonId];
}

