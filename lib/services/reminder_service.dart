import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';

class ReminderService {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: time,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop',
      ),
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> cancelReminder(int id) async {
    await Alarm.stop(id);
  }
}