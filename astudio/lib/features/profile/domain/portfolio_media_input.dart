class PortfolioMediaInput {
  PortfolioMediaInput({
    required this.profileId,
    required this.title,
    required this.mediaUrl,
    this.description,
    this.thumbnailUrl,
    this.mediaType = 'link',
    this.tags = const [],
    this.isPublic = true,
    this.sortOrder,
  });

  final String profileId;
  final String title;
  final String mediaUrl;
  final String? description;
  final String? thumbnailUrl;
  final String mediaType;
  final List<String> tags;
  final bool isPublic;
  final int? sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'title': title,
      'media_url': mediaUrl,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType,
      'tags': tags,
      'is_public': isPublic,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }
}

