import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Check authentication status
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

// Current user email
final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserEmail;
});

// Auth state for UI
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    final isAuthenticated = await _authService.isAuthenticated;
    if (isAuthenticated) {
      final user = await _authService.getCurrentUser();
      state = AuthState(isAuthenticated: true, user: user);
    } else {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authService.signIn(email: email, password: password);

    if (result.success) {
      state = AuthState(isAuthenticated: true, user: result.user);
      return true;
    } else {
      state = AuthState(isAuthenticated: false, error: result.error);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authService.signUp(email: email, password: password);

    if (result.success) {
      state = AuthState(isAuthenticated: true, user: result.user);
      return true;
    } else {
      state = AuthState(isAuthenticated: false, error: result.error);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState(isAuthenticated: false);
  }

  Future<bool> signInWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authService.signInWithBiometric();

    if (result.success) {
      state = AuthState(isAuthenticated: true, user: result.user);
      return true;
    } else {
      state = AuthState(isAuthenticated: false, error: result.error);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
