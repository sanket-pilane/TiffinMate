import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// MUST BE CALLED BEFORE ANY SCHEDULING
  Future<void> initialize() async {
    // Timezone setup
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Platform initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  /// Ask explicitly for permissions — call this from UI (not inside initialize)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final bool? notificationsGranted = await android
          ?.requestNotificationsPermission();
      final bool? exactGranted = await android?.requestExactAlarmsPermission();
      return (notificationsGranted ?? false) && (exactGranted ?? true);
    }

    return false;
  }

  /// Show instant notification
  Future<void> showInstantNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        channelDescription: 'For immediate alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Instant Test ⚡',
      'Notifications are working!',
      details,
    );
  }

  /// Schedule a notification for 5 seconds later
  Future<void> scheduleTestNotification() async {
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 5));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      101,
      'Test After 5 Seconds',
      'This reminder worked! 🎯',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v2',
          'Testing Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print("⏳ Notification scheduled for 5 seconds later");
  }

  /// Schedule recurring reminders (Lunch + Dinner)
  Future<void> scheduleDailyReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll(); // Reset existing

    await _scheduleDaily(
      id: 1,
      title: 'Lunch Time? 🍛',
      body: 'Don\'t forget to log your tiffin entry!',
      hour: 14,
      minute: 0,
    );

    await _scheduleDaily(
      id: 2,
      title: 'Dinner Served? 🍲',
      body: 'Track your dinner to keep your bill accurate.',
      hour: 21,
      minute: 0,
    );
  }

  Future<void> disableNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // ------------ Helpers ----------------

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduled = _nextTime(hour, minute);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders_v2',
          'Daily Reminders',
          channelDescription: 'Daily alerts for tracking meals',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
