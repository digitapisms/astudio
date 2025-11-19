import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOption,
    this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final String correctOption;
  final String? explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>)
          .map((option) => option.toString())
          .toList(),
      correctOption: json['correct_option'] as String,
      explanation: json['explanation'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, prompt, options, correctOption];
}

class LearningQuiz extends Equatable {
  const LearningQuiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.passingScore,
    required this.createdAt,
    required this.updatedAt,
    this.lessonId,
    this.questions = const [],
  });

  final String id;
  final String courseId;
  final String? lessonId;
  final String title;
  final int passingScore;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LearningQuiz.fromJson(Map<String, dynamic> json) {
    return LearningQuiz(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      lessonId: json['lesson_id'] as String?,
      title: json['title'] as String,
      passingScore: json['passing_score'] as int? ?? 70,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, courseId, lessonId, title, passingScore, questions];
}

