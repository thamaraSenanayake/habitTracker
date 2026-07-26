import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';
import 'habit_viewmodel.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.email,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState(status: AuthStatus.loading)) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final loggedIn = await DatabaseHelper.instance.checkAutoLogin();
      if (loggedIn) {
        final email = await DatabaseHelper.instance.getLoggedInUserEmail();
        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(status: AuthStatus.authenticated, email: email);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final success = await DatabaseHelper.instance.verifyAndLoginUser(email, password);
      if (success) {
        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(status: AuthStatus.authenticated, email: email);
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid email or password',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await DatabaseHelper.instance.registerUser(email, password);
      await _ref.read(habitViewModelProvider.notifier).loadData();
      state = AuthState(status: AuthStatus.authenticated, email: email);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await DatabaseHelper.instance.logoutUsers();
      await _ref.read(habitViewModelProvider.notifier).loadData();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
