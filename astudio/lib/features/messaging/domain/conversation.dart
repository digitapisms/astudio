import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.castingId,
    this.isGroup = false,
    this.previewText,
    this.previewAt,
    this.unreadCount = 0,
    this.participantNames = const [],
  });

  final String id;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final String? castingId;
  final bool isGroup;
  final String? previewText;
  final DateTime? previewAt;
  final int unreadCount;
  final List<String> participantNames;

  Conversation copyWith({
    String? previewText,
    DateTime? previewAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      castingId: castingId,
      isGroup: isGroup,
      previewText: previewText ?? this.previewText,
      previewAt: previewAt ?? this.previewAt,
      unreadCount: unreadCount ?? this.unreadCount,
      participantNames: participantNames,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String?,
      castingId: json['casting_id'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      previewText: json['preview_text'] as String?,
      previewAt: json['preview_at'] != null
          ? DateTime.tryParse(json['preview_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      participantNames: (json['participant_names'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'casting_id': castingId,
      'is_group': isGroup,
      'preview_text': previewText,
      'preview_at': previewAt?.toIso8601String(),
      'unread_count': unreadCount,
      'participant_names': participantNames,
    };
  }

  @override
  List<Object?> get props => [id, title, previewText, unreadCount, updatedAt];
}

