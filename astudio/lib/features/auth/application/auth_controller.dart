import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_role.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthViewState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthViewState> {
  StreamSubscription<supa.AuthState>? _authSubscription;

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  ProfileRepository get _profileRepository =>
      ref.read(profileRepositoryProvider);

  @override
  AuthViewState build() {
    Future.microtask(_init);
    ref.onDispose(() => _authSubscription?.cancel());
    return AuthViewState.initial();
  }

  Future<void> _init() async {
    final session = _authRepository.currentSession;
    if (session != null) {
      await _loadProfile(session);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    _authSubscription = _authRepository.authStateChanges().listen((
      authState,
    ) async {
      switch (authState.event) {
        case supa.AuthChangeEvent.initialSession:
        case supa.AuthChangeEvent.signedIn:
        case supa.AuthChangeEvent.tokenRefreshed:
        case supa.AuthChangeEvent.userUpdated:
          final session = authState.session;
          if (session != null) {
            await _loadProfile(session);
          }
          break;
        case supa.AuthChangeEvent.signedOut:
        case supa.AuthChangeEvent.passwordRecovery:
        case supa.AuthChangeEvent.mfaChallengeVerified:
          state = AuthViewState.initial().copyWith(
            status: AuthStatus.unauthenticated,
          );
          break;
        default:
          state = AuthViewState.initial().copyWith(
            status: AuthStatus.unauthenticated,
          );
          break;
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final response = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session != null) {
        await _loadProfile(session);
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isProcessing: false,
          errorMessage: 'Unable to sign in. Please try again.',
        );
      }
    } on supa.AuthException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
    } catch (e) {
      String errorMessage = 'Unexpected error: $e';

      // Provide helpful error messages for common issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed to fetch') ||
          errorString.contains('network') ||
          errorString.contains('cors')) {
        errorMessage =
            'Network error: Unable to connect to Supabase.\n\n'
            'Possible causes:\n'
            '1. Check your internet connection\n'
            '2. Verify SUPABASE_URL in .env is correct\n'
            '3. Ensure your Supabase project is active (not paused)\n'
            '4. Check browser console (F12) for CORS errors';
      } else if (errorString.contains('404') ||
          errorString.contains('not found')) {
        errorMessage =
            'Configuration error: Supabase URL not found.\n\n'
            'Please verify your SUPABASE_URL in .env file is correct.';
      }

      state = state.copyWith(isProcessing: false, errorMessage: errorMessage);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final response = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        data: {'full_name': fullName, 'account_role': role.name},
      );

      final user = response.user;
      final session = response.session ?? _authRepository.currentSession;

      if (user != null && session != null) {
        final profile = await _profileRepository.upsertProfile(
          id: user.id,
          email: email,
          fullName: fullName,
          role: role,
        );
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          profile: profile,
          isProcessing: false,
        );
      } else if (user != null && session == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage:
              'Account created. Please verify your email, then sign in to finish profile setup.',
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          errorMessage:
              'Account created. Please verify your email to continue.',
        );
      }
    } on supa.AuthException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
    } catch (e) {
      String errorMessage = 'Unexpected error: $e';

      // Provide helpful error messages for common issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed to fetch') ||
          errorString.contains('network') ||
          errorString.contains('cors')) {
        errorMessage =
            'Network error: Unable to connect to Supabase.\n\n'
            'Possible causes:\n'
            '1. Check your internet connection\n'
            '2. Verify SUPABASE_URL in .env is correct\n'
            '3. Ensure your Supabase project is active (not paused)\n'
            '4. Check browser console (F12) for CORS errors';
      } else if (errorString.contains('404') ||
          errorString.contains('not found')) {
        errorMessage =
            'Configuration error: Supabase URL not found.\n\n'
            'Please verify your SUPABASE_URL in .env file is correct.';
      }

      state = state.copyWith(isProcessing: false, errorMessage: errorMessage);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = AuthViewState.initial().copyWith(
        status: AuthStatus.unauthenticated,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to sign out: $e');
    }
  }

  Future<void> refreshProfile() async {
    final session = _authRepository.currentSession;
    if (session != null) {
      await _loadProfile(session);
    }
  }

  Future<void> _loadProfile(supa.Session session) async {
    try {
      final user = session.user;
      final metadata = user.userMetadata ?? <String, dynamic>{};
      final userRoleMetadata =
          metadata['account_role'] as String? ?? metadata['role'] as String?;
      final profile = await _profileRepository.fetchProfile(user.id);

      if (profile != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          profile: profile,
          isProcessing: false,
        );
      } else {
        final role = userRoleMetadata != null
            ? UserRole.fromString(userRoleMetadata)
            : UserRole.artist;

        final createdProfile = await _profileRepository.upsertProfile(
          id: user.id,
          email: user.email ?? '',
          fullName:
              (metadata['full_name'] as String?) ?? user.email ?? 'New Talent',
          role: role,
        );
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          profile: createdProfile,
          isProcessing: false,
        );
      }
    } on supa.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        profile: null,
        isProcessing: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        profile: null,
        isProcessing: false,
        errorMessage: 'Unable to load profile: $e',
      );
    }
  }
}
