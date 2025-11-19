import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../application/learning_providers.dart';
import '../domain/learning_course.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(learningCourseDetailProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training course'),
      ),
      body: courseAsync.when(
        data: (course) => _CourseDetailView(course: course),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load course: $error')),
      ),
    );
  }
}

class _CourseDetailView extends ConsumerWidget {
  const _CourseDetailView({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(course.description ?? ''),
        const SizedBox(height: 16),
        Chip(
          label: Text(course.level.label),
        ),
        const SizedBox(height: 24),
        Text(
          'Lessons',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...course.lessons.map(
          (lesson) => Card(
            child: ListTile(
              title: Text(lesson.title),
              subtitle: Text(
                lesson.durationMinutes != null
                    ? '${lesson.durationMinutes} min'
                    : 'Self-paced',
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () => context.pushNamed(
                AppRoute.lessonDetail.name,
                pathParameters: {
                  'courseId': course.id,
                  'lessonId': lesson.id,
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

