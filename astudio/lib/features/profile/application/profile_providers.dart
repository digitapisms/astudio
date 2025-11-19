import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile_review.dart';
import '../domain/portfolio_media.dart';
import '../domain/profile_update_input.dart';
import '../domain/user_profile.dart';

final myProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.profile;
});

final portfolioProvider =
    FutureProvider.autoDispose.family<List<PortfolioMedia>, String>((ref, id) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchPortfolioMedia(id);
});

final profileReviewsProvider =
    FutureProvider.autoDispose.family<List<ProfileReview>, String>((ref, id) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchReviews(id);
});

final profileAverageRatingProvider =
    FutureProvider.autoDispose.family<double, String>((ref, id) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchAverageRating(id);
});

final profileUpdateProvider =
    AsyncNotifierProvider<ProfileUpdateController, void>(
  ProfileUpdateController.new,
);

class ProfileUpdateController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op
  }

  Future<UserProfile> updateProfile(ProfileUpdateInput input) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    try {
      final profile = await repo.updateProfileDetails(input);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      state = const AsyncData(null);
      return profile;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<UserProfile> updateVisibility({
    required String profileId,
    required bool isVisible,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    try {
      final profile = await repo.updateProfileVisibility(
        profileId: profileId,
        isVisible: isVisible,
      );
      await ref.read(authControllerProvider.notifier).refreshProfile();
      state = const AsyncData(null);
      return profile;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

