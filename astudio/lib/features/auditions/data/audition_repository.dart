import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/audition_request.dart';

final auditionRepositoryProvider = Provider<AuditionRepository>((ref) {
  final client = Supabase.instance.client;
  return AuditionRepository(client);
});

class AuditionRepository {
  AuditionRepository(this._client);

  final SupabaseClient _client;

  Future<List<AuditionRequest>> fetchTalentAuditions(String talentId) async {
    final response = await _client
        .from('auditions')
        .select(
          '''
            *,
            castings!inner(title)
          ''',
        )
        .eq('talent_id', talentId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => AuditionRequest.fromJson({
            ...json as Map<String, dynamic>,
            'casting_title': (json['castings'] as Map<String, dynamic>)['title'],
          }),
        )
        .toList();
  }

  Future<List<AuditionRequest>> fetchCastingAuditions(String castingId) async {
    final response = await _client
        .from('auditions')
        .select(
          '''
            *,
            talent:profiles (
              id,
              full_name
            )
          ''',
        )
        .eq('casting_id', castingId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => AuditionRequest.fromJson({
            ...json as Map<String, dynamic>,
            'talent_name': (json['talent'] as Map<String, dynamic>)['full_name'],
          }),
        )
        .toList();
  }

  Future<AuditionRequest> requestAudition({
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
    final response = await _client
        .from('auditions')
        .insert({
          'casting_id': castingId,
          'talent_id': talentId,
          'requested_by': requestedBy,
          'application_id': applicationId,
          'request_type': requestType,
          'instructions': instructions,
          'due_date': dueDate?.toIso8601String(),
          'scheduled_at': scheduledAt?.toIso8601String(),
          'meeting_link': meetingLink,
        })
        .select()
        .single();

    final request = AuditionRequest.fromJson(response);

    await _client.from('notifications').insert({
      'profile_id': talentId,
      'title': 'New ${requestType == 'self_tape' ? 'Self tape' : 'Audition'} request',
      'body':
          'You have been invited to ${requestType.replaceAll('_', ' ')} for this role.',
      'notification_type': 'audition',
      'metadata': {
        'casting_id': castingId,
        'audition_id': request.id,
      },
    });

    return request;
  }

  Future<void> confirmAudition(String auditionId) async {
    await _client
        .from('auditions')
        .update({'status': AuditionStatus.confirmed.name})
        .eq('id', auditionId);
  }

  Future<void> submitSelfTape({
    required String auditionId,
    required String submissionUrl,
  }) async {
    await _client
        .from('auditions')
        .update({
          'submission_url': submissionUrl,
          'status': AuditionStatus.submitted.name,
        })
        .eq('id', auditionId);
  }

  Future<void> reviewSubmission({
    required String auditionId,
    required String status,
    String? notes,
  }) async {
    await _client
        .from('auditions')
        .update({
          'status': status,
          'reviewer_notes': notes,
        })
        .eq('id', auditionId);
  }
}

