import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final client = Supabase.instance.client;
  return NotificationRepository(client);
});

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchNotifications(String profileId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  Future<void> createNotification({
    required String profileId,
    required String title,
    String? body,
    NotificationType type = NotificationType.system,
  }) async {
    await _client.from('notifications').insert({
      'profile_id': profileId,
      'title': title,
      'body': body,
      'notification_type': type.name,
    });
  }
}

