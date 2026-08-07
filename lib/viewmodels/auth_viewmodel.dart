import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../models/user_profile_model.dart';
import 'habit_viewmodel.dart';

enum AuthStatus { loading, authenticated, unauthenticated, onboarding }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? userId;
  final String? errorMessage;
  final bool isCloudSyncEnabled;

  AuthState({
    required this.status,
    this.email,
    this.userId,
    this.errorMessage,
    this.isCloudSyncEnabled = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? userId,
    String? errorMessage,
    bool? isCloudSyncEnabled,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      userId: userId ?? this.userId,
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
      final onboarding = await DatabaseHelper.instance.getSetting('onboarding_completed', 'false');
      if (onboarding == 'true') {
        final carousel = await DatabaseHelper.instance.getSetting('carousel_viewed', 'false');
        final loggedIn = await DatabaseHelper.instance.checkAutoLogin();
        
        final email = loggedIn ? await DatabaseHelper.instance.getLoggedInUserEmail() : null;
        final syncEnabled = email != null && await DatabaseHelper.instance.isCloudSyncEnabled(email);
        final uid = loggedIn ? await DatabaseHelper.instance.getLoggedInUserUid() : null;
        final activeProfileId = await DatabaseHelper.instance.getSetting('active_profile_id', '1');
        
        final userId = loggedIn ? uid : activeProfileId;
        
        // Background load local data
        await _ref.read(habitViewModelProvider.notifier).loadData();
        
        if (carousel == 'true') {
          state = AuthState(
            status: AuthStatus.authenticated,
            email: email,
            userId: userId,
            isCloudSyncEnabled: syncEnabled,
          );
        } else {
          state = AuthState(
            status: AuthStatus.onboarding,
            email: email,
            userId: userId,
            isCloudSyncEnabled: syncEnabled,
          );
        }
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
          await DatabaseHelper.instance.insertHabit(syncedHabit, uid);
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

        // Set onboarding completed
        await DatabaseHelper.instance.saveSetting('onboarding_completed', 'true');

        final carousel = await DatabaseHelper.instance.getSetting('carousel_viewed', 'false');

        // Initialize viewmodel local state
        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(
          status: carousel == 'true' ? AuthStatus.authenticated : AuthStatus.onboarding,
          email: email,
          userId: uid,
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

        // Set onboarding completed
        await DatabaseHelper.instance.saveSetting('onboarding_completed', 'true');

        final carousel = await DatabaseHelper.instance.getSetting('carousel_viewed', 'false');

        await _ref.read(habitViewModelProvider.notifier).loadData();
        state = AuthState(
          status: carousel == 'true' ? AuthStatus.authenticated : AuthStatus.onboarding,
          email: email,
          userId: uid,
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

  Future<void> completeLocalSetup(String name) async {
    try {
      final profile = UserProfileModel(
        name: name,
        avatarUrl: '',
        overallStreak: 12,
        joinedDate: DateFormat('MMMM yyyy').format(DateTime.now()),
      );
      final newProfileId = await DatabaseHelper.instance.insertUserProfile(profile);
      await DatabaseHelper.instance.saveSetting('onboarding_completed', 'true');
      await DatabaseHelper.instance.saveSetting('local_profile_created', 'true');
      await DatabaseHelper.instance.saveSetting('active_profile_id', newProfileId.toString());
      
      await _ref.read(habitViewModelProvider.notifier).loadData();
      state = AuthState(
        status: AuthStatus.onboarding,
        email: null,
        userId: newProfileId.toString(),
        isCloudSyncEnabled: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loginAsLocalUser(String profileId) async {
    try {
      await DatabaseHelper.instance.saveSetting('onboarding_completed', 'true');
      await DatabaseHelper.instance.saveSetting('carousel_viewed', 'true');
      await DatabaseHelper.instance.saveSetting('active_profile_id', profileId);
      
      await _ref.read(habitViewModelProvider.notifier).loadData();
      state = AuthState(
        status: AuthStatus.authenticated,
        email: null,
        userId: profileId,
        isCloudSyncEnabled: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> completeOnboardingCarousel() async {
    try {
      await DatabaseHelper.instance.saveSetting('carousel_viewed', 'true');
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    final wasSynced = state.email != null;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _auth.signOut();
      await DatabaseHelper.instance.logoutUsers();
      
      // Reset onboarding settings
      await DatabaseHelper.instance.saveSetting('onboarding_completed', 'false');
      await DatabaseHelper.instance.saveSetting('carousel_viewed', 'false');
      
      if (wasSynced) {
        // If synced user, clear local profile and reset flag
        await DatabaseHelper.instance.saveSetting('local_profile_created', 'false');
        final defaultProfile = UserProfileModel(
          name: 'Alex',
          avatarUrl: '',
          overallStreak: 12,
          joinedDate: 'October 2024',
        );
        await DatabaseHelper.instance.updateUserProfile(defaultProfile);
      } else {
        // If local-only user, keep the profile and keep local_profile_created true
        await DatabaseHelper.instance.saveSetting('local_profile_created', 'true');
      }
      
      await _ref.read(habitViewModelProvider.notifier).loadData();
      
      state = AuthState(
        status: AuthStatus.unauthenticated,
        email: null,
        userId: null,
        isCloudSyncEnabled: false,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        email: null,
        isCloudSyncEnabled: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
