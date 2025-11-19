import 'package:equatable/equatable.dart';

class CastingCall extends Equatable {
  const CastingCall({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.budget,
    this.city,
    this.country,
    this.location,
    this.applicationDeadline,
    this.shootDate,
    this.requirements = const [],
    this.creator,
    this.applicationCount = 0,
    this.hasApplied = false,
    this.isMine = false,
  });

  final String id;
  final String title;
  final String description;
  final String? category;
  final String? budget;
  final String? city;
  final String? country;
  final String? location;
  final DateTime? applicationDeadline;
  final DateTime? shootDate;
  final List<String> requirements;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CastingCreator? creator;
  final int applicationCount;
  final bool hasApplied;
  final bool isMine;

  bool get isDeadlinePassed =>
      applicationDeadline != null &&
      applicationDeadline!.isBefore(DateTime.now());

  CastingCall copyWith({
    bool? isPublished,
    bool? hasApplied,
    int? applicationCount,
    bool? isMine,
  }) {
    return CastingCall(
      id: id,
      title: title,
      description: description,
      category: category,
      budget: budget,
      city: city,
      country: country,
      location: location,
      applicationDeadline: applicationDeadline,
      shootDate: shootDate,
      requirements: requirements,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      creator: creator,
      applicationCount: applicationCount ?? this.applicationCount,
      hasApplied: hasApplied ?? this.hasApplied,
      isMine: isMine ?? this.isMine,
    );
  }

  factory CastingCall.fromJson(Map<String, dynamic> json) {
    return CastingCall(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      budget: json['budget'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      location: json['location'] as String?,
      applicationDeadline: _parseDate(json['application_deadline']),
      shootDate: _parseDate(json['shoot_date']),
      requirements:
          _parseStringList(json['requirements']) ?? const <String>[],
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: json['creator'] != null
          ? CastingCreator.fromJson(
              json['creator'] as Map<String, dynamic>,
            )
          : null,
      applicationCount: json['application_count'] as int? ?? 0,
      hasApplied: json['has_applied'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'city': city,
      'country': country,
      'location': location,
      'application_deadline': applicationDeadline?.toIso8601String(),
      'shoot_date': shootDate?.toIso8601String(),
      'requirements': requirements,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator': creator?.toJson(),
      'application_count': applicationCount,
      'has_applied': hasApplied,
      'is_mine': isMine,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        city,
        applicationDeadline,
        shootDate,
        isPublished,
        createdAt,
        updatedAt,
        applicationCount,
        hasApplied,
        isMine,
      ];
}

class CastingCreator extends Equatable {
  const CastingCreator({
    required this.id,
    required this.fullName,
    this.profession,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? profession;
  final String? avatarUrl;

  factory CastingCreator.fromJson(Map<String, dynamic> json) {
    return CastingCreator(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      profession: json['profession'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'profession': profession,
      'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [id, fullName, profession, avatarUrl];
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String>? _parseStringList(Object? value) {
  if (value == null) return null;
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return null;
}

