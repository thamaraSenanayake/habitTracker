import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'habit_viewmodel.dart';

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

  Future<void> exportJson(HabitState state, BuildContext context) async {
    try {
      final habits = state.habits;
      final List<Map<String, dynamic>> maps = habits.map((h) => h.toMap()).toList();
      final String jsonContent = jsonEncode(maps);

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/habit_flow_export.json');
        await file.writeAsString(jsonContent);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'HabitFlow Data Export',
          sharePositionOrigin:  Rect.fromLTWH(0, 0, 100, 100),
        );
      } else {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: 'habit_flow_export.json',
          acceptedTypeGroups: const <XTypeGroup>[
            XTypeGroup(label: 'JSON', extensions: <String>['json']),
          ],
        );
        if (result != null) {
          final file = File(result.path);
          await file.writeAsString(jsonContent);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF22C55E),
                content: Text(
                  'Data exported successfully!',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'Export failed: $e',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
      }
    }
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

final notificationSyncProvider = Provider<void>((ref) {
  final habits = ref.watch(habitViewModelProvider).habits;
  final settings = ref.watch(settingsProvider);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.rescheduleAllReminders(
      habits,
      settings.notificationsEnabled,
      settings.soundEnabled,
    );
  });
});
