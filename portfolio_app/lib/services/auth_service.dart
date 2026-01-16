import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;

  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _api = ApiService();
  final _secureStorage = const FlutterSecureStorage();

  static const _biometricEmailKey = 'biometric_email';
  static const _biometricPasswordKey = 'biometric_password';
  static const _userEmailKey = 'user_email';

  // Check if user is authenticated
  Future<bool> get isAuthenticated => _api.isAuthenticated();

  // Get current user email
  Future<String?> get currentUserEmail => _secureStorage.read(key: _userEmailKey);

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;

      // Store token
      await _api.setToken(accessToken);
      await _secureStorage.write(key: _userEmailKey, value: email);

      return AuthResult(success: true, user: data['user']);
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        errorMessage = 'Email already registered';
      }
      return AuthResult(success: false, error: errorMessage);
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;

      // Store token
      await _api.setToken(accessToken);
      await _secureStorage.write(key: _userEmailKey, value: email);

      return AuthResult(success: true, user: data['user']);
    } catch (e) {
      return AuthResult(success: false, error: 'Invalid email or password');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _api.clearToken();
    await _secureStorage.delete(key: _userEmailKey);
  }

  // Get current user from API
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
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
  Future<AuthResult> signInWithBiometric() async {
    final email = await _secureStorage.read(key: _biometricEmailKey);
    final password = await _secureStorage.read(key: _biometricPasswordKey);

    if (email == null || password == null) {
      return AuthResult(success: false, error: 'No biometric credentials stored');
    }

    return signIn(email: email, password: password);
  }

  // Clear biometric credentials
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _biometricEmailKey);
    await _secureStorage.delete(key: _biometricPasswordKey);
  }
}
