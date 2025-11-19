import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/audition_repository.dart';
import '../domain/audition_request.dart';

final talentAuditionsProvider =
    FutureProvider.autoDispose<List<AuditionRequest>>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return [];
  final repo = ref.watch(auditionRepositoryProvider);
  return repo.fetchTalentAuditions(profile.id);
});

final castingAuditionsProvider = FutureProvider.autoDispose
    .family<List<AuditionRequest>, String>((ref, castingId) async {
  final repo = ref.watch(auditionRepositoryProvider);
  return repo.fetchCastingAuditions(castingId);
});

final auditionActionProvider =
    AsyncNotifierProvider<AuditionActionController, void>(
  AuditionActionController.new,
);

class AuditionActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op
  }

  Future<void> requestAudition({
    required String castingId,
    required String talentId,
    required String requestedBy,
    String? applicationId,
    required String requestType,
    String? instructions,
    DateTime? dueDate,
    DateTime? scheduledAt,
    String? meetingLink,
  }) async {
    final repo = ref.read(auditionRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.requestAudition(
        castingId: castingId,
        talentId: talentId,
        requestedBy: requestedBy,
        applicationId: applicationId,
        requestType: requestType,
        instructions: instructions,
        dueDate: dueDate,
        scheduledAt: scheduledAt,
        meetingLink: meetingLink,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> submitSelfTape({
    required String auditionId,
    required String submissionUrl,
  }) async {
    final repo = ref.read(auditionRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.submitSelfTape(
        auditionId: auditionId,
        submissionUrl: submissionUrl,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> reviewSubmission({
    required String auditionId,
    required String status,
    String? notes,
  }) async {
    final repo = ref.read(auditionRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.reviewSubmission(
        auditionId: auditionId,
        status: status,
        notes: notes,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

