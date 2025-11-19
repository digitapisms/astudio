class ProfileUpdateInput {
  ProfileUpdateInput({
    required this.id,
    required this.fullName,
    this.profession,
    this.location,
    this.bio,
    this.gender,
    this.age,
    this.skills = const [],
    this.languages = const [],
    this.instagram,
    this.youtube,
    this.tiktok,
    this.website,
    this.avatarUrl,
    this.bannerUrl,
    this.isVisible,
  });

  final String id;
  final String fullName;
  final String? profession;
  final String? location;
  final String? bio;
  final String? gender;
  final int? age;
  final List<String> skills;
  final List<String> languages;
  final String? instagram;
  final String? youtube;
  final String? tiktok;
  final String? website;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool? isVisible;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'profession': profession,
      'location': location,
      'bio': bio,
      'gender': gender,
      'age': age,
      'skills': skills,
      'languages': languages,
      'instagram': instagram,
      'youtube': youtube,
      'tiktok': tiktok,
      'website': website,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'is_visible': isVisible,
    }..removeWhere((key, value) => value == null);
  }
}
