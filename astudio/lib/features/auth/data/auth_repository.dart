import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = supa.Supabase.instance.client;
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);

  final supa.SupabaseClient _client;

  supa.Session? get currentSession => _client.auth.currentSession;

  Stream<supa.AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<supa.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<supa.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() => _client.auth.signOut();
}
