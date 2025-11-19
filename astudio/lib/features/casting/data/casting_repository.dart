import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/casting_application.dart';
import '../domain/casting_call.dart';
import '../domain/casting_filter.dart';

final castingRepositoryProvider = Provider<CastingRepository>((ref) {
  final client = Supabase.instance.client;
  return CastingRepository(client);
});

class CastingRepository {
  CastingRepository(this._client);

  final SupabaseClient _client;

  Future<List<CastingCall>> fetchCastings({
    required CastingFilter filter,
    String? currentProfileId,
  }) async {
    final PostgrestFilterBuilder query = _client
        .from('castings')
        .select(
          '''
            *,
            creator:profiles (
              id,
              full_name,
              profession,
              avatar_url
            )
          ''',
        );

    if (!filter.onlyMine) {
      query.eq('is_published', true);
    }

    if (filter.city != null && filter.city!.isNotEmpty) {
      query.ilike('city', '%${filter.city!}%');
    }

    if (filter.category != null && filter.category!.isNotEmpty) {
      query.eq('category', filter.category!);
    }

    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      query.textSearch(
        'title',
        filter.searchTerm!,
        config: 'english',
        type: TextSearchType.websearch,
      );
    }

    if (filter.onlyMine && currentProfileId != null) {
      query.eq('created_by', currentProfileId);
    }

    if (filter.onlyOpen) {
      query.or(
        'application_deadline.is.null,application_deadline.gte.${DateTime.now().toIso8601String()}',
      );
    }

    Set<String> appliedCastingIds = {};
    if (currentProfileId != null && !filter.onlyMine) {
      final appliedRows = await _client
          .from('applications')
          .select('casting_id')
          .eq('talent_id', currentProfileId);
      appliedCastingIds = (appliedRows as List<dynamic>)
          .map((row) => row['casting_id'] as String)
          .toSet();
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => _mapCastingWithFlags(
            json,
            currentProfileId,
            hasAppliedFlag: appliedCastingIds.contains(json['id'] as String),
          ),
        )
        .toList();
  }

  Future<CastingCall> fetchCastingById(
    String castingId, {
    String? currentProfileId,
  }) async {
    final response = await _client
        .from('castings')
        .select(
          '''
            *,
            creator:profiles (
              id,
              full_name,
              profession,
              avatar_url
            )
          ''',
        )
        .eq('id', castingId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Casting not found');
    }

    bool hasAppliedFlag = false;
    if (currentProfileId != null) {
      hasAppliedFlag = await hasApplied(
        castingId: castingId,
        talentId: currentProfileId,
      );
    }

    return _mapCastingWithFlags(
      response,
      currentProfileId,
      hasAppliedFlag: hasAppliedFlag,
    );
  }

  Future<CastingCall> createOrUpdateCasting({
    String? castingId,
    required Map<String, dynamic> payload,
  }) async {
    const selectColumns = '''
            *,
            creator:profiles (
              id,
              full_name,
              profession,
              avatar_url
            )
          ''';

    if (castingId == null) {
      final response = await _client
          .from('castings')
          .insert(payload)
          .select(selectColumns)
          .single();
      return CastingCall.fromJson(response);
    } else {
      final response = await _client
          .from('castings')
          .update(payload)
          .eq('id', castingId)
          .select(selectColumns)
          .single();
      return CastingCall.fromJson(response);
    }
  }

  Future<void> publishCasting({
    required String castingId,
    required bool isPublished,
  }) async {
    await _client
        .from('castings')
        .update({'is_published': isPublished}).eq('id', castingId);
  }

  Future<void> deleteCasting(String castingId) async {
    await _client.from('castings').delete().eq('id', castingId);
  }

  Future<bool> hasApplied({
    required String castingId,
    required String talentId,
  }) async {
    final response = await _client
        .from('applications')
        .select('id')
        .eq('casting_id', castingId)
        .eq('talent_id', talentId)
        .maybeSingle();

    return response != null;
  }

  Future<CastingApplication> submitApplication({
    required String castingId,
    required String talentId,
    required String coverLetter,
    List<String>? mediaUrls,
  }) async {
    final response = await _client
        .from('applications')
        .insert({
          'casting_id': castingId,
          'talent_id': talentId,
          'cover_letter': coverLetter,
          'media_urls': mediaUrls ?? <String>[],
        })
        .select(
          '''
            *,
            talent:profiles (
              id,
              full_name,
              account_role,
              status,
              avatar_url,
              location,
              profession
            )
          ''',
        )
        .single();

    return CastingApplication.fromJson(response);
  }

  Future<List<CastingApplication>> fetchApplicationsForCasting(
    String castingId,
  ) async {
    final response = await _client
        .from('applications')
        .select(
          '''
            *,
            talent:profiles (
              id,
              full_name,
              account_role,
              status,
              avatar_url,
              location,
              profession
            )
          ''',
        )
        .eq('casting_id', castingId)
        .order('submitted_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => CastingApplication.fromJson(json))
        .toList();
  }

  Future<List<CastingApplication>> fetchMyApplications(
    String talentId,
  ) async {
    final response = await _client
        .from('applications')
        .select(
          '''
            *,
            casting:castings (
              id,
              title,
              city,
              application_deadline,
              category
            )
          ''',
        )
        .eq('talent_id', talentId)
        .order('submitted_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => CastingApplication.fromJson(json))
        .toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _client
        .from('applications')
        .update({'status': status}).eq('id', applicationId);
  }

  CastingCall _mapCastingWithFlags(
    Map<String, dynamic> json,
    String? currentProfileId, {
    bool hasAppliedFlag = false,
  }) {
    final casting = CastingCall.fromJson(json);
    final isMine = currentProfileId != null &&
        casting.creator != null &&
        casting.creator!.id == currentProfileId;

    return casting.copyWith(
      hasApplied: hasAppliedFlag,
      applicationCount:
          json['application_count'] as int? ?? casting.applicationCount,
      isMine: isMine,
    );
  }
}

class CastingDraft {
  CastingDraft({
    required this.title,
    required this.description,
    this.createdBy,
    this.category,
    this.budget,
    this.city,
    this.country,
    this.location,
    this.applicationDeadline,
    this.shootDate,
    this.requirements = const [],
    this.isPublished = false,
  });

  final String title;
  final String description;
  final String? createdBy;
  final String? category;
  final String? budget;
  final String? city;
  final String? country;
  final String? location;
  final DateTime? applicationDeadline;
  final DateTime? shootDate;
  final List<String> requirements;
  final bool isPublished;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'created_by': createdBy,
      'category': category,
      'budget': budget,
      'city': city,
      'country': country,
      'location': location,
      'application_deadline': applicationDeadline?.toIso8601String(),
      'shoot_date': shootDate?.toIso8601String(),
      'requirements': requirements,
      'is_published': isPublished,
    }..removeWhere((key, value) => value == null);
  }
}

