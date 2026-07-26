import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_flow/models/user_profile_model.dart';

import '../models/habit_model.dart';
import '../services/database_helper.dart';

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
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  HabitViewModel()
    : super(HabitState(habits: [], selectedDate: _getTodayString())) {
    loadData();
  }
  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final habits = await _dbHelper.getAllHabits();
    final profile = await _dbHelper.getUserProfile();
    state = state.copyWith(
      habits: habits,
      userProfile: profile,
      isLoading: false,
    );
  }

  void selectDate(String dateStr) {
    state = state.copyWith(selectedDate: dateStr);
  }

  void setFilterCategory(String category) {
    state = state.copyWith(filterCategory: category);
  }

  Future<void> toggleHabit(String habitId) async {
    final updatedHabits = state.habits.map((h) {
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
      );

      _dbHelper.updateHabit(updated);
      return updated;
    }).toList();

    state = state.copyWith(habits: updatedHabits);
  }

  Future<void> addHabit(HabitModel newHabit) async {
    await _dbHelper.insertHabit(newHabit);
    await loadData();
  }

  Future<void> deleteHabit(String habitId) async {
    await _dbHelper.deleteHabit(habitId);
    await loadData();
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    await _dbHelper.updateUserProfile(profile);
    state = state.copyWith(userProfile: profile);
  }
}

// Global Riverpod Provider definition
final habitViewModelProvider =
    StateNotifierProvider<HabitViewModel, HabitState>((ref) {
      return HabitViewModel();
    });
