import 'package:equatable/equatable.dart';

class ProfileReview extends Equatable {
  const ProfileReview({
    required this.id,
    required this.profileId,
    required this.reviewerId,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.comment,
    this.reviewerName,
  });

  final String id;
  final String profileId;
  final String reviewerId;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final String? comment;
  final String? reviewerName;

  factory ProfileReview.fromJson(Map<String, dynamic> json) {
    return ProfileReview(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      rating: json['rating'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      reviewerName: json['reviewer'] != null
          ? (json['reviewer'] as Map<String, dynamic>)['full_name'] as String?
          : json['reviewer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reviewer_name': reviewerName,
    };
  }

  @override
  List<Object?> get props =>
      [id, rating, profileId, reviewerId, comment, createdAt];
}

