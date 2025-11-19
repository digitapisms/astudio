import 'package:equatable/equatable.dart';

enum NotificationType { profile, audition, casting, system }

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.system,
    );
  }

  String get label {
    switch (this) {
      case NotificationType.profile:
        return 'Profile';
      case NotificationType.audition:
        return 'Audition';
      case NotificationType.casting:
        return 'Casting';
      case NotificationType.system:
        return 'System';
    }
  }
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.profileId,
    required this.title,
    required this.createdAt,
    required this.type,
    this.body,
    this.readAt,
  });

  final String id;
  final String profileId;
  final String title;
  final String? body;
  final NotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: NotificationTypeX.fromString(
        json['notification_type'] as String? ?? 'system',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, title, profileId, readAt, createdAt];
}

