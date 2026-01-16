import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  final _api = ApiService();

  static const _biometricEmailKey = 'biometric_email';
  static const _biometricPasswordKey = 'biometric_password';

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Sync with backend to create user record
    if (response.user != null) {
      await _syncUserWithBackend();
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Sync with backend
    if (response.user != null) {
      await _syncUserWithBackend();
    }

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Store credentials for biometric login
  Future<void> storeBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _biometricEmailKey, value: email);
    await _secureStorage.write(key: _biometricPasswordKey, value: password);
  }

  // Check if biometric credentials exist
  Future<bool> hasBiometricCredentials() async {
    final email = await _secureStorage.read(key: _biometricEmailKey);
    return email != null;
  }

  // Sign in with biometric
  Future<AuthResponse?> signInWithBiometric() async {
    final email = await _secureStorage.read(key: _biometricEmailKey);
    final password = await _secureStorage.read(key: _biometricPasswordKey);

    if (email == null || password == null) {
      return null;
    }

    return signIn(email: email, password: password);
  }

  // Clear biometric credentials
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _biometricEmailKey);
    await _secureStorage.delete(key: _biometricPasswordKey);
  }

  // Sync user with backend
  Future<void> _syncUserWithBackend() async {
    try {
      await _api.get('/auth/me');
    } catch (e) {
      // Backend will create user if doesn't exist
      // Ignore errors here, they'll be handled elsewhere
    }
  }
}
