import 'package:equatable/equatable.dart';

import '../../profile/domain/user_profile.dart';

class CastingApplication extends Equatable {
  const CastingApplication({
    required this.id,
    required this.castingId,
    required this.talentId,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    this.coverLetter,
    this.mediaUrls = const [],
    this.talentSummary,
  });

  final String id;
  final String castingId;
  final String talentId;
  final String status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String? coverLetter;
  final List<String> mediaUrls;
  final UserProfile? talentSummary;

  CastingApplication copyWith({String? status}) {
    return CastingApplication(
      id: id,
      castingId: castingId,
      talentId: talentId,
      status: status ?? this.status,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      coverLetter: coverLetter,
      mediaUrls: mediaUrls,
      talentSummary: talentSummary,
    );
  }

  factory CastingApplication.fromJson(Map<String, dynamic> json) {
    return CastingApplication(
      id: json['id'] as String,
      castingId: json['casting_id'] as String,
      talentId: json['talent_id'] as String,
      status: json['status'] as String? ?? 'submitted',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      coverLetter: json['cover_letter'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      talentSummary: json['talent'] != null
          ? UserProfile.fromJson(json['talent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'casting_id': castingId,
      'talent_id': talentId,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cover_letter': coverLetter,
      'media_urls': mediaUrls,
      'talent': talentSummary?.toJson(),
    };
  }

  @override
  List<Object?> get props =>
      [id, castingId, talentId, status, submittedAt, updatedAt];
}

