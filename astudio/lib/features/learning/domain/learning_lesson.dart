import 'package:equatable/equatable.dart';

import 'learning_quiz.dart';

class LearningLesson extends Equatable {
  const LearningLesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.videoUrl,
    this.durationMinutes,
    this.quiz,
  });

  final String id;
  final String courseId;
  final String title;
  final String? content;
  final String? videoUrl;
  final int orderIndex;
  final int? durationMinutes;
  final LearningQuiz? quiz;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    return LearningLesson(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      videoUrl: json['video_url'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      quiz: json['quiz'] != null
          ? LearningQuiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, courseId, orderIndex, durationMinutes, quiz];
}

