import 'package:shared_preferences/shared_preferences.dart';

class StreakData {
  final int current;
  final int best;

  StreakData({required this.current, required this.best});
}

class StreakService {
  static Future<void> recordCompletion() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toIso8601String().substring(0, 10);
    String? lastDate = prefs.getString("last_date");

    int currentStreak = prefs.getInt("streak") ?? 0;
    int bestStreak = prefs.getInt("best_streak") ?? 0;

    if (lastDate == null) {
      currentStreak = 1;
    } else {
      DateTime last = DateTime.parse(lastDate);
      DateTime now = DateTime.now();

      int diff = now.difference(last).inDays;

      if (diff == 1) {
        currentStreak += 1;
      } else if (diff > 1) {
        currentStreak = 1;
      }
      // if diff == 0 → same day → do nothing
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    await prefs.setString("last_date", today);
    await prefs.setInt("streak", currentStreak);
    await prefs.setInt("best_streak", bestStreak);
  }

  static Future<StreakData> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();

    return StreakData(
      current: prefs.getInt("streak") ?? 0,
      best: prefs.getInt("best_streak") ?? 0,
    );
  }
}