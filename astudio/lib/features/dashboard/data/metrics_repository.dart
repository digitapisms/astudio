import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_metrics.dart';

final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  final client = Supabase.instance.client;
  return MetricsRepository(client);
});

class MetricsRepository {
  MetricsRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileMetrics> fetchMetrics(String profileId) async {
    final notificationsRaw = await _client
        .from('notifications')
        .select('id, created_at')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    final reviewsRaw = await _client
        .from('profile_feedback')
        .select('id')
        .eq('profile_id', profileId);

    final auditionsRaw = await _client
        .from('auditions')
        .select('id')
        .eq('talent_id', profileId);

    final notifications = (notificationsRaw as List<dynamic>);
    final reviews = (reviewsRaw as List<dynamic>);
    final auditions = (auditionsRaw as List<dynamic>);

    DateTime? lastSeen;
    if (notifications.isNotEmpty) {
      final createdAt =
          (notifications.first as Map<String, dynamic>)['created_at'] as String?;
      if (createdAt != null) {
        lastSeen = DateTime.tryParse(createdAt);
      }
    }

    return ProfileMetrics(
      profileId: profileId,
      profileViews: notifications.length,
      saves: reviews.length,
      auditionInvites: auditions.length,
      lastProfileView: lastSeen,
    );
  }
}

