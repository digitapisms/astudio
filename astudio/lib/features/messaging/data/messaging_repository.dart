import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/conversation.dart';
import '../domain/message.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final client = Supabase.instance.client;
  return MessagingRepository(client);
});

class MessagingRepository {
  MessagingRepository(this._client);

  final SupabaseClient _client;

  Future<List<Conversation>> fetchConversations(String profileId) async {
    final response = await _client
        .from('conversations')
        .select(
          '''
            *,
            participants:conversation_participants (
              profiles (full_name)
            ),
            last_message:messages!messages_conversation_id_fkey (
              content,
              created_at
            )
          ''',
        )
        .filter('participants.profile_id', 'eq', profileId)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>).map((json) {
      final map = json as Map<String, dynamic>;
      final rawParticipants =
          map['participants'] as List<dynamic>? ?? const [];
      final participants = rawParticipants
          .map(
            (participant) => (participant as Map<String, dynamic>)['profiles']
                    ['full_name'] as String? ??
                '',
          )
          .where((name) => name.isNotEmpty)
          .toList();
      Map<String, dynamic>? lastMessage;
      final rawLast = map['last_message'];
      if (rawLast is List && rawLast.isNotEmpty) {
        final first = rawLast.first;
        if (first is Map<String, dynamic>) {
          lastMessage = first;
        }
      }
      return Conversation.fromJson({
        ...map,
        'participant_names': participants,
        'preview_text': lastMessage != null ? lastMessage['content'] : null,
        'preview_at': lastMessage != null ? lastMessage['created_at'] : null,
      });
    }).toList();
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select(
          '''
            *,
            sender:profiles (full_name)
          ''',
        )
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      final sender =
          (map['sender'] as Map<String, dynamic>?)?['full_name'] as String?;
      map['sender_name'] = sender;
      return Message.fromJson(map);
    }).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? attachmentUrl,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
          'attachment_url': attachmentUrl,
        })
        .select(
          '''
            *,
            sender:profiles (full_name)
          ''',
        )
        .single();

    final map = Map<String, dynamic>.from(response);
    final sender =
        (map['sender'] as Map<String, dynamic>?)?['full_name'] as String?;
    map['sender_name'] = sender;
    return Message.fromJson(map);
  }

  Future<Conversation> createConversation({
    String? title,
    String? castingId,
    required String createdBy,
    required List<String> participantIds,
  }) async {
    final response = await _client
        .from('conversations')
        .insert({
          'title': title,
          'casting_id': castingId,
          'created_by': createdBy,
          'is_group': participantIds.length > 1,
        })
        .select()
        .single();

    final conversationId = response['id'] as String;
    await _client.from('conversation_participants').insert([
      for (final id in participantIds)
        {
          'conversation_id': conversationId,
          'profile_id': id,
          'role': id == createdBy ? 'owner' : 'member',
        },
    ]);

    return Conversation.fromJson(response);
  }
}

