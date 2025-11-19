import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../application/messaging_providers.dart';
import '../domain/conversation.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final router = GoRouter.of(context);
          final newId = await router.pushNamed<String>(
            AppRoute.newConversation.name,
          );
          if (newId != null) {
            router.pushNamed(
              AppRoute.conversationDetail.name,
              pathParameters: {'conversationId': newId},
            );
            ref.invalidate(conversationsProvider);
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('New message'),
      ),
      body: conversations.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Start a conversation with talent or producers to collaborate.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final conversation = items[index];
              return _ConversationTile(conversation: conversation);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load conversations: $error')),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final subtitle = conversation.previewText ?? 'Tap to view conversation';
    final title = conversation.title ??
        (conversation.participantNames.isNotEmpty
            ? conversation.participantNames.join(', ')
            : 'Conversation');

    return Card(
      child: ListTile(
        onTap: () => context.pushNamed(
          AppRoute.conversationDetail.name,
          pathParameters: {'conversationId': conversation.id},
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: conversation.unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.sunsetGold,
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.richBlack,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

