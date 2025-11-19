import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationFeedProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return [];
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchNotifications(profile.id);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final feed = ref.watch(notificationFeedProvider).maybeWhen(
        data: (data) => data,
        orElse: () => const <AppNotification>[],
      );
  return feed.where((notification) => notification.readAt == null).length;
});

