import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),

      /// 🔥 REQUIRED FIX (IMPORTANT)
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      /// 🔥 DAILY REPEAT (GOOD FOR DEMO)
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }
}