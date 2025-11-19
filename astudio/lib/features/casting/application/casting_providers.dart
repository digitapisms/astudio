import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/casting_repository.dart';
import '../domain/casting_application.dart';
import '../domain/casting_call.dart';
import '../domain/casting_filter.dart';

final castingFilterProvider =
    NotifierProvider<CastingFilterController, CastingFilter>(
  CastingFilterController.new,
);

final castingFeedProvider =
    FutureProvider.autoDispose<List<CastingCall>>((ref) async {
  final filter = ref.watch(castingFilterProvider);
  final repo = ref.watch(castingRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final profileId = authState.profile?.id;
  return repo.fetchCastings(filter: filter, currentProfileId: profileId);
});

final castingDetailProvider =
    FutureProvider.family.autoDispose<CastingCall, String>((ref, id) async {
  final repo = ref.watch(castingRepositoryProvider);
  final profileId = ref.watch(authControllerProvider).profile?.id;
  return repo.fetchCastingById(id, currentProfileId: profileId);
});

final castingApplicationsProvider = FutureProvider.autoDispose
    .family<List<CastingApplication>, String>((ref, castingId) async {
  final repo = ref.watch(castingRepositoryProvider);
  return repo.fetchApplicationsForCasting(castingId);
});

class CastingFilterController extends Notifier<CastingFilter> {
  @override
  CastingFilter build() => const CastingFilter();

  void updateSearch(String value) {
    state = state.copyWith(searchTerm: value.isEmpty ? null : value);
  }

  void updateCity(String value) {
    state = state.copyWith(city: value.isEmpty ? null : value);
  }

  void updateCategory(String? value) {
    state = state.copyWith(category: value?.isEmpty == true ? null : value);
  }

  void toggleOnlyOpen(bool value) {
    state = state.copyWith(onlyOpen: value);
  }

  void toggleOnlyMine(bool value) {
    state = state.copyWith(onlyMine: value);
  }

  void reset() {
    state = const CastingFilter();
  }
}

