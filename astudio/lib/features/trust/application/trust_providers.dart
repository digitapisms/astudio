import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/trust_repository.dart';
import '../domain/identity_verification_request.dart';

final identityVerificationProvider =
    FutureProvider.autoDispose<IdentityVerificationRequest?>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return null;
  final repo = ref.watch(trustRepositoryProvider);
  return repo.fetchLatestVerification(profile.id);
});

final policyAcknowledgementProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return false;
  final repo = ref.watch(trustRepositoryProvider);
  return repo.hasAcknowledgedPolicy(
    profileId: profile.id,
    policyKey: 'code_of_conduct',
    policyVersion: 'v1',
  );
});

