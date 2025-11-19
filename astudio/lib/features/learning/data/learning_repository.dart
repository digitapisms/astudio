import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/learning_course.dart';
import '../domain/learning_lesson.dart';
import '../domain/learning_progress.dart';
import '../domain/learning_quiz.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  final client = Supabase.instance.client;
  return LearningRepository(client);
});

class LearningRepository {
  LearningRepository(this._client);

  final SupabaseClient _client;

  Future<List<LearningCourse>> fetchCourses(String profileId) async {
    final response = await _client
        .from('learning_courses')
        .select(
          '''
            *,
            progress:learning_progress(
              id,
              status,
              completed_lessons,
              last_lesson_id,
              completed_at,
              last_accessed_at
            )
          ''',
        )
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => _mapCourse(
            Map<String, dynamic>.from(json as Map),
            profileId,
          ),
        )
        .toList();
  }

  Future<LearningCourse> fetchCourseDetail(
    String courseId,
    String profileId,
  ) async {
    final response = await _client
        .from('learning_courses')
        .select(
          '''
            *,
            lessons:learning_lessons(
              *,
              quiz:learning_quizzes(
                *,
                questions:learning_quiz_questions(*)
              )
            ),
            progress:learning_progress(
              id,
              status,
              completed_lessons,
              last_lesson_id,
              completed_at,
              last_accessed_at
            )
          ''',
        )
        .eq('id', courseId)
        .single();
    return _mapCourse(
      Map<String, dynamic>.from(response as Map),
      profileId,
    );
  }

  Future<LearningProgress> upsertProgress({
    required String profileId,
    required String courseId,
    String? lastLessonId,
    List<String>? completedLessons,
    String? status,
  }) async {
    final payload = {
      'profile_id': profileId,
      'course_id': courseId,
      if (lastLessonId != null) 'last_lesson_id': lastLessonId,
      if (completedLessons != null) 'completed_lessons': completedLessons,
      if (status != null) 'status': status,
      'last_accessed_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('learning_progress')
        .upsert(payload)
        .select()
        .single();
    return LearningProgress.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<MessageResult> submitQuizAttempt({
    required String profileId,
    required String quizId,
    required List<String> answers,
  }) async {
    final quizResponse = await _client
        .from('learning_quizzes')
        .select(
          '''
            *,
            questions:learning_quiz_questions(*)
          ''',
        )
        .eq('id', quizId)
        .maybeSingle();
    if (quizResponse == null) throw Exception('Quiz not found');

    final quiz = LearningQuiz.fromJson(quizResponse);
    final total = quiz.questions.length;
    int correct = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      if (i < answers.length &&
          quiz.questions[i].correctOption == answers[i]) {
        correct++;
      }
    }
    final score = ((correct / total) * 100).round();
    final passed = score >= quiz.passingScore;

    await _client.from('learning_quiz_attempts').insert({
      'quiz_id': quizId,
      'profile_id': profileId,
      'score': score,
      'passed': passed,
      'answers': answers,
    });

    return MessageResult(score: score, passed: passed);
  }

  LearningCourse _mapCourse(
    Map<String, dynamic> json,
    String profileId,
  ) {
    final lessons = ((json['lessons'] as List<dynamic>?)
                ?.map(
                  (lesson) => LearningLesson.fromJson(
                    lesson as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            <LearningLesson>[])
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    Map<String, dynamic>? progressJson;
    if (json['progress'] is List) {
      for (final entry in json['progress'] as List<dynamic>) {
        final map = Map<String, dynamic>.from(entry as Map);
        if (map['profile_id'] == profileId) {
          progressJson = map;
          break;
        }
      }
    } else if (json['progress'] is Map) {
      final map = Map<String, dynamic>.from(json['progress'] as Map);
      if (map['profile_id'] == profileId) {
        progressJson = map;
      }
    }

    return LearningCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      level: CourseLevelX.fromString(
        json['level'] as String? ?? 'beginner',
      ),
      durationMinutes: json['duration_minutes'] as int?,
      coverImageUrl: json['cover_image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      isPublished: json['is_published'] as bool? ?? false,
      lessons: lessons,
      progress:
          progressJson != null ? LearningProgress.fromJson(progressJson) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class MessageResult {
  MessageResult({required this.score, required this.passed});
  final int score;
  final bool passed;
}

