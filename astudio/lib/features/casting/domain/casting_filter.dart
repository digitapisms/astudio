import 'package:equatable/equatable.dart';

class CastingFilter extends Equatable {
  const CastingFilter({
    this.searchTerm,
    this.city,
    this.category,
    this.onlyOpen = true,
    this.onlyMine = false,
  });

  final String? searchTerm;
  final String? city;
  final String? category;
  final bool onlyOpen;
  final bool onlyMine;

  CastingFilter copyWith({
    String? searchTerm,
    String? city,
    String? category,
    bool? onlyOpen,
    bool? onlyMine,
  }) {
    return CastingFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      city: city ?? this.city,
      category: category ?? this.category,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      onlyMine: onlyMine ?? this.onlyMine,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'search': searchTerm,
      'city': city,
      'category': category,
      'onlyOpen': onlyOpen,
      'onlyMine': onlyMine,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [searchTerm, city, category, onlyOpen, onlyMine];
}

