import 'package:equatable/equatable.dart';

import 'profile_status.dart';
import 'user_role.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.bannerUrl,
    this.location,
    this.profession,
    this.bio,
    this.gender,
    this.age,
    this.skills = const [],
    this.languages = const [],
    this.instagram,
    this.youtube,
    this.tiktok,
    this.website,
    this.reviewNotes,
    this.approvedBy,
    this.approvedAt,
    this.isVisible = false,
    this.featuredRank,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final ProfileStatus status;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? location;
  final String? profession;
  final String? bio;
  final String? gender;
  final int? age;
  final List<String> skills;
  final List<String> languages;
  final String? instagram;
  final String? youtube;
  final String? tiktok;
  final String? website;
  final String? reviewNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool isVisible;
  final int? featuredRank;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status.isAwaitingReview;
  bool get isApproved => status.isActive;
  bool get isRejected => status.isRejected;

  UserProfile copyWith({
    String? fullName,
    UserRole? role,
    ProfileStatus? status,
    String? avatarUrl,
    String? bannerUrl,
    String? location,
    String? profession,
    String? bio,
    String? gender,
    int? age,
    List<String>? skills,
    List<String>? languages,
    String? instagram,
    String? youtube,
    String? tiktok,
    String? website,
    String? reviewNotes,
    String? approvedBy,
    DateTime? approvedAt,
    bool? isVisible,
    int? featuredRank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      location: location ?? this.location,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      tiktok: tiktok ?? this.tiktok,
      website: website ?? this.website,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isVisible: isVisible ?? this.isVisible,
      featuredRank: featuredRank ?? this.featuredRank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    status,
    avatarUrl,
    bannerUrl,
    location,
    profession,
    bio,
    gender,
    age,
    skills,
    languages,
    instagram,
    youtube,
    tiktok,
    website,
    reviewNotes,
    approvedBy,
    approvedAt,
    isVisible,
    featuredRank,
    createdAt,
    updatedAt,
  ];

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: UserRole.fromString(
        json['account_role'] as String? ??
            json['role'] as String? ??
            UserRole.artist.name,
      ),
      status: ProfileStatus.fromString(
        json['status'] as String? ?? ProfileStatus.pending.name,
      ),
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      location: json['location'] as String?,
      profession: json['profession'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      skills: _parseList(json['skills']),
      languages: _parseList(json['languages']),
      instagram: json['instagram'] as String?,
      youtube: json['youtube'] as String?,
      tiktok: json['tiktok'] as String?,
      website: json['website'] as String?,
      reviewNotes: json['review_notes'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: _tryParseDate(json['approved_at']),
      isVisible: (json['is_visible'] as bool?) ?? false,
      featuredRank: json['featured_rank'] as int?,
      createdAt: _tryParseDate(json['created_at']),
      updatedAt: _tryParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'account_role': role.name,
      'status': status.name,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'location': location,
      'profession': profession,
      'bio': bio,
      'gender': gender,
      'age': age,
      'skills': skills,
      'languages': languages,
      'instagram': instagram,
      'youtube': youtube,
      'tiktok': tiktok,
      'website': website,
      'review_notes': reviewNotes,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'is_visible': isVisible,
      'featured_rank': featuredRank,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

DateTime? _tryParseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _parseList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}
