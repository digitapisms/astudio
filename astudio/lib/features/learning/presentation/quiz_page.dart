import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../application/learning_providers.dart';
import '../data/learning_repository.dart';
import '../domain/learning_quiz.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key, required this.courseId, required this.quizId});

  final String courseId;
  final String quizId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(learningCourseDetailProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: courseAsync.when(
        data: (course) {
          final quiz = course.lessons
              .where((lesson) => lesson.quiz?.id == widget.quizId)
              .map((lesson) => lesson.quiz)
              .firstWhere((quiz) => quiz != null, orElse: () => null);

          if (quiz == null) {
            return const Center(child: Text('Quiz not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...quiz.questions.map(
                (question) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.prompt,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final option in question.options)
                          _AnswerOptionTile(
                            label: option,
                            selected: _answers[question.id] == option,
                            onTap: () {
                              setState(() {
                                _answers[question.id] = option;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitQuiz(quiz),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit quiz'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load quiz: $error')),
      ),
    );
  }

  Future<void> _submitQuiz(LearningQuiz quiz) async {
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(authControllerProvider).profile;
      if (profile == null) throw Exception('Profile required');
      final repo = ref.read(learningRepositoryProvider);
      final orderedAnswers = quiz.questions
          .map((question) => _answers[question.id] ?? '')
          .toList();
      final result = await repo.submitQuizAttempt(
        profileId: profile.id,
        quizId: quiz.id,
        answers: orderedAnswers,
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(result.passed ? 'Passed!' : 'Try again'),
          content: Text('Score: ${result.score}%'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit quiz: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Colors.blueGrey.withValues(alpha: 0.2) : null,
      child: ListTile(
        leading: Icon(
          selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}

