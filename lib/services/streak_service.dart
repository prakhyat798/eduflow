import 'package:shared_preferences/shared_preferences.dart';

class StreakData {
  final int current;
  final int best;

  StreakData({required this.current, required this.best});
}

class StreakService {
  static Future<void> recordCompletion() async {
    final prefs = await SharedPreferences.getInstance();

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String? lastDate = prefs.getString("last_date");

    int currentStreak = prefs.getInt("streak") ?? 0;
    int bestStreak = prefs.getInt("best_streak") ?? 0;

    if (lastDate == null) {
      // First ever session
      currentStreak = 1;
    } else if (lastDate == today) {
      // Already recorded today — do nothing, don't double-count
    } else {
      // Check if lastDate was exactly yesterday using date arithmetic
      final last = DateTime.parse(lastDate);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final lastDateStr = last.toIso8601String().substring(0, 10);
      final yesterdayStr = yesterday.toIso8601String().substring(0, 10);

      if (lastDateStr == yesterdayStr) {
        // Consecutive day — extend streak
        currentStreak += 1;
      } else {
        // Missed a day — reset
        currentStreak = 1;
      }
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