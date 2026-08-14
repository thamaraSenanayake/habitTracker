import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../models/user_profile_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'auth_viewmodel.dart';

// State wrapper for ViewModel
class HabitState {
  final List<HabitModel> habits;
  final UserProfileModel? userProfile;
  final String selectedDate;
  final String filterCategory;
  final bool isLoading;

  HabitState({
    required this.habits,
    this.userProfile,
    required this.selectedDate,
    this.filterCategory = 'all',
    this.isLoading = false,
  });

  HabitState copyWith({
    List<HabitModel>? habits,
    UserProfileModel? userProfile,
    String? selectedDate,
    String? filterCategory,
    bool? isLoading,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      userProfile: userProfile ?? this.userProfile,
      selectedDate: selectedDate ?? this.selectedDate,
      filterCategory: filterCategory ?? this.filterCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get completedCount {
    return habits.where((h) => h.completedDates.contains(selectedDate)).length;
  }

  int get totalCount => habits.length;

  int get completionPercentage {
    if (totalCount == 0) return 0;
    return ((completedCount / totalCount) * 100).round();
  }
}

// Riverpod ViewModel Notifier
class HabitViewModel extends StateNotifier<HabitState> {
  final Ref _ref;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  HabitViewModel(this._ref)
      : super(HabitState(habits: [], selectedDate: _getTodayString())) {
    loadData();
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    
    final habits = await _dbHelper.getAllHabits(activeUserId);
    final profile = await _dbHelper.getUserProfile(activeUserId);
    
    state = state.copyWith(
      habits: habits,
      userProfile: profile,
      isLoading: false,
    );

    // Trigger dynamic sync check in background if cloud sync is enabled
    final uid = await _dbHelper.getLoggedInUserUid();
    final email = await _dbHelper.getLoggedInUserEmail();
    if (uid != null && email != null) {
      final cloudSyncEnabled = await _dbHelper.isCloudSyncEnabled(email);
      if (cloudSyncEnabled) {
        syncPendingHabits(uid);
      }
    }
  }

  Future<void> syncPendingHabits(String uid) async {
    await SyncService.syncPending(uid);
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    // Reload habits to get updated isSynced status flags
    final habits = await _dbHelper.getAllHabits(activeUserId);
    state = state.copyWith(habits: habits);
  }

  void selectDate(String dateStr) {
    state = state.copyWith(selectedDate: dateStr);
  }

  void setFilterCategory(String category) {
    state = state.copyWith(filterCategory: category);
  }

  Future<void> toggleHabit(String habitId) async {
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    
    final uid = await _dbHelper.getLoggedInUserUid();
    final email = await _dbHelper.getLoggedInUserEmail();
    final cloudSyncEnabled = uid != null && email != null && await _dbHelper.isCloudSyncEnabled(email);

    final updatedHabits = await Future.wait(state.habits.map((h) async {
      if (h.id != habitId) return h;

      final dateStr = state.selectedDate;
      final isCompleted = h.completedDates.contains(dateStr);
      List<String> newDates = List.from(h.completedDates);

      if (isCompleted) {
        newDates.remove(dateStr);
      } else {
        newDates.add(dateStr);
      }

      final updated = h.copyWith(
        completedDates: newDates,
        currentCount: !isCompleted ? h.targetCount : 0,
        isSynced: cloudSyncEnabled ? 0 : 1,
      );

      await _dbHelper.updateHabit(updated, activeUserId);

      if (cloudSyncEnabled && uid != null) {
        final success = await SyncService.uploadHabit(uid, updated);
        if (success) {
          await _dbHelper.markHabitSynced(updated.id);
          return updated.copyWith(isSynced: 1);
        }
      }
      return updated;
    }).toList());

    state = state.copyWith(habits: updatedHabits);
  }

  Future<void> addHabit(HabitModel newHabit) async {
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    
    final uid = await _dbHelper.getLoggedInUserUid();
    final email = await _dbHelper.getLoggedInUserEmail();
    final cloudSyncEnabled = uid != null && email != null && await _dbHelper.isCloudSyncEnabled(email);

    final habitToSave = newHabit.copyWith(
      isSynced: cloudSyncEnabled ? 0 : 1,
    );

    await _dbHelper.insertHabit(habitToSave, activeUserId);
    await loadData();

    if (cloudSyncEnabled && uid != null) {
      SyncService.uploadHabit(uid, habitToSave).then((success) async {
        if (success) {
          await _dbHelper.markHabitSynced(habitToSave.id);
          await loadData();
        }
      });
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    
    final uid = await _dbHelper.getLoggedInUserUid();
    final email = await _dbHelper.getLoggedInUserEmail();
    final cloudSyncEnabled = uid != null && email != null && await _dbHelper.isCloudSyncEnabled(email);

    await _dbHelper.deleteHabit(habitId, activeUserId);
    await loadData();

    if (cloudSyncEnabled && uid != null) {
      SyncService.deleteHabit(uid, habitId);
    }
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    final authState = _ref.read(authProvider);
    final String activeUserId = authState.userId ?? '1';
    final updatedProfile = profile.copyWith(userId: activeUserId);
    
    await _dbHelper.updateUserProfile(updatedProfile);
    state = state.copyWith(userProfile: updatedProfile);

    final uid = await _dbHelper.getLoggedInUserUid();
    final email = await _dbHelper.getLoggedInUserEmail();
    if (uid != null && email != null) {
      final cloudSyncEnabled = await _dbHelper.isCloudSyncEnabled(email);
      if (cloudSyncEnabled) {
        SyncService.uploadProfile(uid, updatedProfile);
      }
    }
  }
}

// Global Riverpod Provider definition
final habitViewModelProvider =
    StateNotifierProvider<HabitViewModel, HabitState>((ref) {
      final viewModel = HabitViewModel(ref);
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (previous?.userId != next.userId || previous?.status != next.status) {
          viewModel.loadData();
        }
      });
      return viewModel;
    });
