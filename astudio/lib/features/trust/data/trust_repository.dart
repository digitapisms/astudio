import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/identity_verification_request.dart';
import '../domain/safety_report.dart';

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  final client = Supabase.instance.client;
  return TrustRepository(client);
});

class TrustRepository {
  TrustRepository(this._client);

  final SupabaseClient _client;

  Future<IdentityVerificationRequest?> fetchLatestVerification(
    String profileId,
  ) async {
    final response = await _client
        .from('identity_verifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .maybeSingle();
    if (response == null) return null;
    final map = Map<String, dynamic>.from(response);
    return IdentityVerificationRequest.fromJson(map);
  }

  Future<IdentityVerificationRequest> submitVerification({
    required String profileId,
    required String documentUrl,
    String? documentType,
  }) async {
    final response = await _client
        .from('identity_verifications')
        .insert({
          'profile_id': profileId,
          'document_url': documentUrl,
          'document_type': documentType,
        })
        .select()
        .single();
    return IdentityVerificationRequest.fromJson(response);
  }

  Future<SafetyReport> submitSafetyReport({
    required String reporterId,
    String? targetProfileId,
    required String category,
    String? description,
  }) async {
    final response = await _client
        .from('safety_reports')
        .insert({
          'reporter_id': reporterId,
          'target_profile_id': targetProfileId,
          'category': category,
          'description': description,
        })
        .select()
        .single();
    return SafetyReport.fromJson(response);
  }

  Future<bool> hasAcknowledgedPolicy({
    required String profileId,
    required String policyKey,
    required String policyVersion,
  }) async {
    final response = await _client
        .from('policy_acknowledgements')
        .select('id')
        .eq('profile_id', profileId)
        .eq('policy_key', policyKey)
        .eq('policy_version', policyVersion)
        .maybeSingle();
    return response != null;
  }

  Future<void> acknowledgePolicy({
    required String profileId,
    required String policyKey,
    required String policyVersion,
  }) async {
    await _client.from('policy_acknowledgements').insert({
      'profile_id': profileId,
      'policy_key': policyKey,
      'policy_version': policyVersion,
    });
  }
}

