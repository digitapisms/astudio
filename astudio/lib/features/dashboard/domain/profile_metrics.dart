import 'package:equatable/equatable.dart';

class ProfileMetrics extends Equatable {
  const ProfileMetrics({
    required this.profileId,
    required this.profileViews,
    required this.saves,
    required this.auditionInvites,
    this.lastProfileView,
  });

  final String profileId;
  final int profileViews;
  final int saves;
  final int auditionInvites;
  final DateTime? lastProfileView;

  factory ProfileMetrics.fromJson(Map<String, dynamic> json) {
    return ProfileMetrics(
      profileId: json['profile_id'] as String,
      profileViews: (json['profile_views'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      auditionInvites: (json['audition_invites'] as num?)?.toInt() ?? 0,
      lastProfileView: json['last_profile_view'] != null
          ? DateTime.tryParse(json['last_profile_view'] as String)
          : null,
    );
  }

  ProfileMetrics copyWith({
    int? profileViews,
    int? saves,
    int? auditionInvites,
    DateTime? lastProfileView,
  }) {
    return ProfileMetrics(
      profileId: profileId,
      profileViews: profileViews ?? this.profileViews,
      saves: saves ?? this.saves,
      auditionInvites: auditionInvites ?? this.auditionInvites,
      lastProfileView: lastProfileView ?? this.lastProfileView,
    );
  }

  @override
  List<Object?> get props =>
      [profileId, profileViews, saves, auditionInvites, lastProfileView];
}

