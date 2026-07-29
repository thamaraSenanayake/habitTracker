import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';

// App Settings state holding notifications and sound variables
class AppSettingsState {
  final bool notificationsEnabled;
  final bool soundEnabled;

  AppSettingsState({
    required this.notificationsEnabled,
    required this.soundEnabled,
  });

  AppSettingsState copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
  }) {
    return AppSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

// Notifier for theme configuration
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  ThemeNotifier() : super(ThemeMode.dark) {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _loadTheme();
    }
  }

  void _loadTheme() async {
    final modeStr = await _db.getSetting('theme_mode', 'dark');
    state = modeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _db.saveSetting('theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
  }
}

// Notifier for general app switch preferences
class SettingsNotifier extends StateNotifier<AppSettingsState> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  SettingsNotifier()
      : super(AppSettingsState(notificationsEnabled: true, soundEnabled: true)) {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _loadSettings();
    }
  }

  void _loadSettings() async {
    final notifStr = await _db.getSetting('notifications_enabled', 'true');
    final soundStr = await _db.getSetting('sound_enabled', 'true');
    state = AppSettingsState(
      notificationsEnabled: notifStr == 'true',
      soundEnabled: soundStr == 'true',
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _db.saveSetting('notifications_enabled', enabled ? 'true' : 'false');
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _db.saveSetting('sound_enabled', enabled ? 'true' : 'false');
  }
}

// Global Providers
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
      return SettingsNotifier();
    });
