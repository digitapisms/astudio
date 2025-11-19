import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/domain/user_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewState extends Equatable {
  const AuthViewState({
    required this.status,
    this.session,
    this.profile,
    this.isProcessing = false,
    this.errorMessage,
  });

  factory AuthViewState.initial() =>
      const AuthViewState(status: AuthStatus.unknown);

  final AuthStatus status;
  final Session? session;
  final UserProfile? profile;
  final bool isProcessing;
  final String? errorMessage;

  AuthViewState copyWith({
    AuthStatus? status,
    Session? session,
    UserProfile? profile,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      session: session ?? this.session,
      profile: profile ?? this.profile,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    profile,
    isProcessing,
    errorMessage,
  ];
}
