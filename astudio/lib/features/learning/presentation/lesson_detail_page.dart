import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../application/learning_providers.dart';
import '../data/learning_repository.dart';
import '../domain/learning_course.dart';
import '../domain/learning_lesson.dart';

class LessonDetailPage extends ConsumerWidget {
  const LessonDetailPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(learningCourseDetailProvider(courseId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
      ),
      body: courseAsync.when(
        data: (course) {
          LearningLesson? lesson;
          for (final entry in course.lessons) {
            if (entry.id == lessonId) {
              lesson = entry;
              break;
            }
          }
          if (lesson == null) {
            return const Center(child: Text('Lesson not found'));
          }
          return _LessonContent(course: course, lesson: lesson);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load lesson: $error')),
      ),
    );
  }
}

class _LessonContent extends ConsumerWidget {
  const _LessonContent({required this.course, required this.lesson});

  final LearningCourse course;
  final LearningLesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final repo = ref.watch(learningRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (lesson.videoUrl != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_outline, size: 64),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          lesson.content ?? 'Coming soon...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (lesson.quiz != null)
          ElevatedButton.icon(
            onPressed: () => context.pushNamed(
              AppRoute.quiz.name,
              pathParameters: {
                'courseId': course.id,
                'quizId': lesson.quiz!.id,
              },
            ),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Take quiz'),
          ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: profile == null
              ? null
              : () async {
                  final updatedLessons = <String>{
                    ...?course.progress?.completedLessons,
                    lesson.id,
                  }.toList();
                  await repo.upsertProgress(
                    profileId: profile.id,
                    courseId: course.id,
                    lastLessonId: lesson.id,
                    completedLessons: updatedLessons,
                    status: lesson.orderIndex == course.lessons.length - 1
                        ? 'completed'
                        : 'in_progress',
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress saved')),
                  );
                  ref.invalidate(learningCourseDetailProvider(course.id));
                },
          child: const Text('Mark lesson complete'),
        ),
      ],
    );
  }
}

