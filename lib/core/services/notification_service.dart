import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? notificationsGranted = await androidImplementation
          ?.requestNotificationsPermission();

      final bool? exactAlarmsGranted = await androidImplementation
          ?.requestExactAlarmsPermission();

      return (notificationsGranted ?? false) && (exactAlarmsGranted ?? true);
    }
    return false;
  }

  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'instant_channel',
          'Instant Notifications',
          channelDescription: 'For testing immediate notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Instant Test ⚡',
      'If you see this, basic notifications are working!',
      notificationDetails,
    );
  }

  Future<void> scheduleTestNotification() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 5));

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

      print("⏳ Notification scheduled for 5 seconds from now");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  Future<void> scheduleDailyReminders() async {
    await _cancelAll();

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
    await _cancelAll();
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders_v2',
          'Daily Reminders',
          channelDescription: 'Reminds you to log your meals',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
