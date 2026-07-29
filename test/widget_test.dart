import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_flow/main.dart';
import 'package:habit_flow/viewmodels/habit_viewmodel.dart';
import 'package:habit_flow/viewmodels/auth_viewmodel.dart';
import 'package:habit_flow/viewmodels/theme_viewmodel.dart';
import 'package:habit_flow/models/habit_model.dart';
import 'package:habit_flow/models/user_profile_model.dart';

class MockHabitViewModel extends HabitViewModel {
  MockHabitViewModel() : super();

  @override
  Future<void> loadData() async {
    state = HabitState(
      selectedDate: '2026-07-26',
      habits: [
        HabitModel(
          id: '1',
          title: 'Drink Water',
          subtitle: 'Stay hydrated',
          icon: 'water_drop',
          category: 'hydration',
          targetCount: 2,
          unit: 'L',
          currentCount: 1,
          colorBg: '0x338083FF',
          colorText: '0xFFC0C1FF',
          streakDays: 12,
          completedDates: ['2026-07-26'],
          logs: {'2026-07-26': 1},
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
      userProfile: UserProfileModel(
        name: 'Alex',
        avatarUrl: '',
        overallStreak: 12,
        joinedDate: 'October 2024',
      ),
    );
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(Ref ref) : super(ref);

  @override
  Future<void> checkLoginStatus() async {
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<bool> signIn(String email, String password) async {
    state = AuthState(status: AuthStatus.authenticated, email: email);
    return true;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    state = AuthState(status: AuthStatus.authenticated, email: email);
    return true;
  }

  @override
  Future<void> toggleCloudSync(bool enabled) async {
    state = state.copyWith(isCloudSyncEnabled: enabled);
  }

  @override
  Future<void> signOut() async {
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

class MockThemeNotifier extends ThemeNotifier {
  MockThemeNotifier() : super();

  @override
  void _loadTheme() {
    state = ThemeMode.dark;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
  }
}

class MockSettingsNotifier extends SettingsNotifier {
  MockSettingsNotifier() : super();

  @override
  void _loadSettings() {
    state = AppSettingsState(notificationsEnabled: true, soundEnabled: true);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
  }
}

void main() {
  testWidgets('Full Authentication and navigation smoke test', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitViewModelProvider.overrideWith((ref) => MockHabitViewModel()),
            authProvider.overrideWith((ref) => MockAuthNotifier(ref)),
            themeProvider.overrideWith((ref) => MockThemeNotifier()),
            settingsProvider.overrideWith((ref) => MockSettingsNotifier()),
          ],
          child: const HabitFlowApp(),
        ),
      );

      // Verify that we start on the SignInView
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Enter mock credentials
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'alex@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your password'), 'password123');
      await tester.pumpAndSettle();

      // Tap Sign In button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Verify that we successfully logged in and transitioned to TodayView
      expect(find.text("Today's Habits"), findsOneWidget);
      expect(find.text("Drink Water"), findsOneWidget);

      // Tap on the habit card to navigate to HabitDetailView
      await tester.tap(find.text('Drink Water'));
      await tester.pumpAndSettle();

      // Verify HabitDetailView is visible and shows details
      expect(find.text('Drink Water'), findsWidgets);
      expect(find.text('Current Streak'), findsOneWidget);

      // Go back to today view
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Tap the FAB to navigate to AddHabitView
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify AddHabitView is visible
      expect(find.text('Create New Habit'), findsOneWidget);

      // Go back to today view
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap on the Settings navigation item in bottom bar
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Verify Settings page contains profile with the correct email
      expect(find.text('alex@example.com'), findsOneWidget);

      // Tap the Sign Out button
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Verify that we are transitioned back to the SignInView
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    }, createHttpClient: (context) => _MockHttpClient());
  });
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 43;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final bytes = base64Decode(
        'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
    return Stream<List<int>>.fromIterable([bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
