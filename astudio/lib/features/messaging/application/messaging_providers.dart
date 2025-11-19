import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/messaging_repository.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final profile = ref.watch(authControllerProvider).profile;
  if (profile == null) return [];
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.fetchConversations(profile.id);
});

final messagesProvider = FutureProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.fetchMessages(conversationId);
});

final messageComposerProvider =
    AsyncNotifierProvider<MessageComposerController, void>(
  MessageComposerController.new,
);

class MessageComposerController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null) throw Exception('Profile missing');
    final repo = ref.read(messagingRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.sendMessage(
        conversationId: conversationId,
        senderId: profile.id,
        content: content,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

