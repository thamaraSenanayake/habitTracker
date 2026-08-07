import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'habit_flow_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDesc = 'Daily reminders to complete your habits';

  /// Initialize local notifications and local timezone settings
  static Future<void> init() async {
    // Shield from unit tests where method channels are not mocked
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      final TimezoneInfo timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));

      // 2. Initialize Notifications Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_notification');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Request initial permissions on launch (if not prompted yet)
      await requestPermissions();
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Request permissions on Android (13+) and iOS
  static Future<void> requestPermissions() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Reschedule all active reminders based on habit configuration
  static Future<void> rescheduleAllReminders(
    List<HabitModel> habits,
    bool globalEnabled,
    bool soundEnabled,
  ) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      // Clear all existing reminders first to avoid duplicates or orphaned alerts
      await _notificationsPlugin.cancelAll();

      if (!globalEnabled) {
        debugPrint('Global notifications are disabled. All alarms cancelled.');
        return;
      }

      int scheduledCount = 0;

      for (final habit in habits) {
        final timeOfDay = _parseTime(habit.reminderTime);
        if (timeOfDay == null) continue;

        final notificationId = habit.id.hashCode & 0x7FFFFFFF;

        final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        // If time already passed today, schedule starting tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: soundEnabled,
        );

        final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        );

        final NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'Time for ${habit.title}!',
          body: habit.subtitle.isNotEmpty ? habit.subtitle : 'Keep up the streak!',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
          payload: habit.id,
        );

        scheduledCount++;
      }

      debugPrint('Scheduled $scheduledCount daily habit reminder notifications.');
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  /// Helper parser to map "08:30 AM" or "08:30 PM" to TimeOfDay
  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final cleanStr = timeStr.trim();
      final parts = cleanStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        final ampm = parts[1].toLowerCase();
        if (ampm == 'pm' && hour < 12) {
          hour += 12;
        } else if (ampm == 'am' && hour == 12) {
          hour = 0;
        }
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing reminder time "$timeStr": $e');
      return null;
    }
  }
}
