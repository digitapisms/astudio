import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/metrics_repository.dart';
import '../domain/profile_metrics.dart';

final profileMetricsProvider =
    FutureProvider.autoDispose<ProfileMetrics>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) {
    throw Exception('Profile not available');
  }
  final repo = ref.watch(metricsRepositoryProvider);
  return repo.fetchMetrics(profile.id);
});

