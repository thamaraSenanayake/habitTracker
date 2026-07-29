import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../models/user_profile_model.dart';
import 'habit_viewmodel.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final bool isCloudSyncEnabled;

  AuthState({
    required this.status,
    this.email,
    this.errorMessage,
    this.isCloudSyncEnabled = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
    bool? isCloudSyncEnabled,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: errorMessage ?? this.errorMessage,
      isCloudSyncEnabled: isCloudSyncEnabled ?? this.isCloudSyncEnabled,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  AuthNotifier(this._ref) : super(AuthState(status: AuthStatus.loading)) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final loggedIn = await DatabaseHelper.instance.checkAutoLogin();
      if (loggedIn) {
        final email = await DatabaseHelper.instance.getLoggedInUserEmail();
        final syncEnabled = email != null && await DatabaseHelper.instance.isCloudSyncEnabled(email);
        
        // Background load local data
        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          isCloudSyncEnabled: syncEnabled,
        );
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

    // First login check: must have active internet connection
    final hasInternet = await SyncService.hasInternetConnection();
    if (!hasInternet) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Internet connection is required for first-time login',
      );
      return false;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;

        // Save session locally in SQLite without password
        await DatabaseHelper.instance.verifyAndLoginUser(email, uid);
        final syncEnabled = await DatabaseHelper.instance.isCloudSyncEnabled(email);

        // Download existing cloud data if available
        final downloadedHabits = await SyncService.downloadHabits(uid);
        for (final habit in downloadedHabits) {
          // Mark downloaded items as already synced locally
          final syncedHabit = habit.copyWith(isSynced: 1);
          await DatabaseHelper.instance.insertHabit(syncedHabit);
        }

        // Download existing profile if available
        final downloadedProfile = await SyncService.downloadProfile(uid);
        if (downloadedProfile != null) {
          await DatabaseHelper.instance.updateUserProfile(downloadedProfile);
        } else {
          // Restore user profile default name
          final profileName = email.split('@')[0];
          final defaultProfile = UserProfileModel(
            name: profileName[0].toUpperCase() + profileName.substring(1),
            avatarUrl: '',
            overallStreak: 12,
            joinedDate: DateFormat('MMMM yyyy').format(DateTime.now()),
          );
          await DatabaseHelper.instance.updateUserProfile(defaultProfile);
        }

        // Initialize viewmodel local state
        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          isCloudSyncEnabled: syncEnabled,
        );
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign In failed: User not found',
        );
        return false;
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message ?? 'Invalid email or password',
      );
      return false;
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

    // First login check: must have active internet connection
    final hasInternet = await SyncService.hasInternetConnection();
    if (!hasInternet) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Internet connection is required for first-time sign up',
      );
      return false;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;

        // Save session locally in SQLite
        await DatabaseHelper.instance.registerUser(email, uid);

        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          isCloudSyncEnabled: false,
        );
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign Up failed',
        );
        return false;
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message ?? 'Sign Up failed',
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> toggleCloudSync(bool enabled) async {
    final email = state.email;
    if (email != null) {
      await DatabaseHelper.instance.updateCloudSyncSetting(email, enabled);
      state = state.copyWith(isCloudSyncEnabled: enabled);

      if (enabled) {
        final uid = await DatabaseHelper.instance.getLoggedInUserUid();
        if (uid != null) {
          _ref.read(habitViewModelProvider.notifier).syncPendingHabits(uid);
        }
      }
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _auth.signOut();
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
