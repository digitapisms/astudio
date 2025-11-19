import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/shimmer_blocks.dart';
import '../../../router/app_router.dart';
import '../../learning/application/learning_providers.dart';
import '../../learning/domain/learning_course.dart';

class LearningHubPage extends ConsumerWidget {
  const LearningHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(learningCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(
              child: Text(
                'Training programs are coming soon. Check back for new lessons!',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(course: course);
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(itemCount: 3, itemHeight: 90),
        ),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load courses: $error')),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    final subtitle = course.description ?? 'Self-paced course';
    final progress = course.progress;
    final progressText = progress == null
        ? 'Not started'
        : progress.isCompleted
            ? 'Completed'
            : '${progress.completedLessons.length} lessons completed';
    final meta = course.lessons.isNotEmpty
        ? '${course.lessons.length} lessons'
        : course.durationMinutes != null
            ? '${course.durationMinutes} min'
            : 'Self-paced';

    return Card(
      child: ListTile(
        onTap: () => context.pushNamed(
          AppRoute.courseDetail.name,
          pathParameters: {'courseId': course.id},
        ),
        title: Text(course.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              '${course.level.label} • $meta • $progressText',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

