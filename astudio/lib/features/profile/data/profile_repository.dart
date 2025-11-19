import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../domain/portfolio_media.dart';
import '../domain/portfolio_media_input.dart';
import '../domain/profile_review.dart';
import '../domain/profile_status.dart';
import '../domain/profile_update_input.dart';
import '../domain/user_profile.dart';
import '../domain/user_role.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = supa.Supabase.instance.client;
  return ProfileRepository(client);
});

class ProfileRepository {
  ProfileRepository(this._client);

  final supa.SupabaseClient _client;

  Future<UserProfile?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserProfile.fromJson(response);
  }

  Future<UserProfile> upsertProfile({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    final updates = {
      'id': id,
      'email': email,
      'full_name': fullName,
      'account_role': role.name,
      'status': role.isStaff
          ? ProfileStatus.approved.name
          : ProfileStatus.pending.name,
      'is_visible': role.isStaff,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('profiles')
        .upsert(updates)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to upsert profile');
    }

    return UserProfile.fromJson(response);
  }

  Future<List<UserProfile>> fetchPendingProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('status', ProfileStatus.pending.name)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> reviewProfile({
    required String profileId,
    required ProfileStatus status,
    String? notes,
  }) async {
    final response = await _client
        .from('profiles')
        .update({
          'status': status.name,
          'review_notes': notes,
          'approved_by': _client.auth.currentUser?.id,
          'approved_at': DateTime.now().toIso8601String(),
          'is_visible': status == ProfileStatus.approved,
        })
        .eq('id', profileId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to update profile status');
    }

    await _client.from('profile_reviews').insert({
      'profile_id': profileId,
      'reviewer_id': _client.auth.currentUser?.id,
      'status': status.name,
      'notes': notes,
    });

    await _client.from('notifications').insert({
      'profile_id': profileId,
      'title': status == ProfileStatus.approved
          ? 'Your profile was approved'
          : status == ProfileStatus.rejected
              ? 'Profile requires updates'
              : 'Profile status updated',
      'body': notes ??
          (status == ProfileStatus.approved
              ? 'You can now access casting calls and opportunities.'
              : 'Review the feedback and resubmit when you are ready.'),
      'notification_type': 'profile',
    });

    return UserProfile.fromJson(response);
  }

  Future<void> bulkReviewProfiles({
    required List<String> profileIds,
    required ProfileStatus status,
    String? notes,
  }) async {
    for (final id in profileIds) {
      await reviewProfile(
        profileId: id,
        status: status,
        notes: notes,
      );
    }
  }

  Future<void> deleteProfile(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }

  Future<UserProfile?> findProfileByEmail(String email) async {
    final response = await _client
        .from('profiles')
        .select()
        .ilike('email', email)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<List<ProfileReview>> fetchReviews(String profileId) async {
    final response = await _client
        .from('profile_feedback')
        .select(
          '''
            *,
            reviewer:profiles (
              id,
              full_name
            )
          ''',
        )
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => ProfileReview.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<double> fetchAverageRating(String profileId) async {
    final response = await _client
        .from('profile_feedback')
        .select('rating')
        .eq('profile_id', profileId);
    final ratings = (response as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['rating'] as int? ?? 0)
        .toList();
    if (ratings.isEmpty) return 0;
    final sum = ratings.fold<int>(0, (prev, next) => prev + next);
    return sum / ratings.length;
  }

  Future<ProfileReview> submitReview({
    required String profileId,
    required String reviewerId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    final response = await _client
        .from('profile_feedback')
        .upsert({
          'profile_id': profileId,
          'reviewer_id': reviewerId,
          'rating': rating,
          'title': title,
          'comment': comment,
        })
        .select(
          '''
            *,
            reviewer:profiles (
              full_name
            )
          ''',
        )
        .single();

    return ProfileReview.fromJson(response);
  }

  Future<UserProfile> updateProfileDetails(ProfileUpdateInput input) async {
    final payload = input.toJson()
      ..['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('profiles')
        .update(payload)
        .eq('id', input.id)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to update profile');
    }

    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateProfileVisibility({
    required String profileId,
    required bool isVisible,
  }) async {
    final response = await _client
        .from('profiles')
        .update({
          'is_visible': isVisible,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', profileId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to update visibility');
    }

    return UserProfile.fromJson(response);
  }

  Future<List<PortfolioMedia>> fetchPortfolioMedia(String profileId) async {
    final response = await _client
        .from('portfolio_media')
        .select()
        .eq('profile_id', profileId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => PortfolioMedia.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PortfolioMedia> savePortfolioMedia({
    String? mediaId,
    required PortfolioMediaInput input,
  }) async {
    final payload = input.toJson()
      ..['updated_at'] = DateTime.now().toIso8601String();

    Map<String, dynamic> response;
    if (mediaId == null) {
      response = await _client
          .from('portfolio_media')
          .insert(payload)
          .select()
          .single();
    } else {
      final updatePayload = Map<String, dynamic>.from(payload)
        ..remove('profile_id');
      response = await _client
          .from('portfolio_media')
          .update(updatePayload)
          .eq('id', mediaId)
          .select()
          .single();
    }

    return PortfolioMedia.fromJson(response);
  }

  Future<void> deletePortfolioMedia(String mediaId) async {
    await _client.from('portfolio_media').delete().eq('id', mediaId);
  }
}
