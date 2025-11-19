import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/learning_repository.dart';
import '../domain/learning_course.dart';
import '../domain/learning_progress.dart';

final learningCoursesProvider =
    FutureProvider.autoDispose<List<LearningCourse>>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return [];
  final repo = ref.watch(learningRepositoryProvider);
  return repo.fetchCourses(profile.id);
});

final learningCourseDetailProvider =
    FutureProvider.autoDispose.family<LearningCourse, String>(
  (ref, courseId) async {
    final profile = ref.watch(authControllerProvider).profile;
    if (profile == null) throw Exception('Not authenticated');
    final repo = ref.watch(learningRepositoryProvider);
    return repo.fetchCourseDetail(courseId, profile.id);
  },
);

final learningProgressProvider =
    FutureProvider.autoDispose.family<LearningProgress?, String>(
  (ref, courseId) async {
    final profile = ref.watch(authControllerProvider).profile;
    if (profile == null) return null;
    final detail = await ref.watch(learningCourseDetailProvider(courseId).future);
    return detail.progress;
  },
);

