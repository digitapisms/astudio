import 'package:equatable/equatable.dart';

class PortfolioMedia extends Equatable {
  const PortfolioMedia({
    required this.id,
    required this.profileId,
    required this.title,
    required this.mediaUrl,
    required this.mediaType,
    required this.isPublic,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.thumbnailUrl,
    this.tags = const [],
  });

  final String id;
  final String profileId;
  final String title;
  final String mediaUrl;
  final PortfolioMediaType mediaType;
  final bool isPublic;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? thumbnailUrl;
  final List<String> tags;

  PortfolioMedia copyWith({
    String? title,
    String? mediaUrl,
    PortfolioMediaType? mediaType,
    bool? isPublic,
    int? sortOrder,
    String? description,
    String? thumbnailUrl,
    List<String>? tags,
  }) {
    return PortfolioMedia(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isPublic: isPublic ?? this.isPublic,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
    );
  }

  factory PortfolioMedia.fromJson(Map<String, dynamic> json) {
    return PortfolioMedia(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: PortfolioMediaType.fromString(
        json['media_type'] as String? ?? 'link',
      ),
      isPublic: json['is_public'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'title': title,
      'media_url': mediaUrl,
      'media_type': mediaType.name,
      'is_public': isPublic,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'tags': tags,
    };
  }

  @override
  List<Object?> get props => [id, profileId, title, mediaUrl, mediaType, sortOrder];
}

enum PortfolioMediaType { image, video, link;

  static PortfolioMediaType fromString(String value) {
    return PortfolioMediaType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PortfolioMediaType.link,
    );
  }

  String get label {
    switch (this) {
      case PortfolioMediaType.image:
        return 'Image';
      case PortfolioMediaType.video:
        return 'Video';
      case PortfolioMediaType.link:
        return 'Link';
    }
  }
}

