import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatsScreen extends StatefulWidget {
  final bool isDark;

  const StatsScreen({super.key, required this.isDark});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // We use dynamic here to avoid type errors when parsing the lists
  List<dynamic> tasks = [];
  List<dynamic> habits = [];

  int todayMinutes = 0;
  int totalMinutes = 0;
  bool _isLoading = true;

  int _selectedTab = 0;

  final Color bgDark = const Color(0xFF0A0616);
  final Color cardDark = const Color(0xFF1A132C);
  final Color accentPurple = const Color(0xFF9147FF);
  final Color accentGreen = const Color(0xFF0CBF83);
  final Color textMutedDark = const Color(0xFF8A849C);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🔥 FIXED CORE LOGIC: Correctly parsing the SharedPreferences data
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Load Tasks safely
      final String? tasksData = prefs.getString('tasks');
      if (tasksData != null) {
        tasks = jsonDecode(tasksData);
      }

      // 2. Load Habits safely
      final String? habitsData = prefs.getString('habits');
      if (habitsData != null) {
        habits = jsonDecode(habitsData);
      }

      // 3. Load Focus Minutes
      setState(() {
        todayMinutes = prefs.getInt("today_minutes") ?? 0;
        totalMinutes = prefs.getInt("total_minutes") ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading stats data: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTab(String title, int index, Color mutedColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : mutedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 FIXED LOGIC: Using ['completed'] map access to match our Item class structure
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t['completed'] == true).length;

    final totalHabits = habits.length;
    final completedHabits = habits.where((h) => h['completed'] == true).length;

    int currentTotal = 0;
    int currentCompleted = 0;
    String emptyStateText = "";

    if (_selectedTab == 0) {
      currentTotal = totalTasks + totalHabits;
      currentCompleted = completedTasks + completedHabits;
      emptyStateText = "No goals set yet";
    } else if (_selectedTab == 1) {
      currentTotal = totalTasks;
      currentCompleted = completedTasks;
      emptyStateText = "No tasks set yet";
    } else {
      currentTotal = totalHabits;
      currentCompleted = completedHabits;
      emptyStateText = "No habits set yet";
    }

    final currentPending = currentTotal - currentCompleted;
    final progress = currentTotal == 0 ? 0.0 : currentCompleted / currentTotal;

    final backgroundColor = widget.isDark ? bgDark : Colors.grey[50];
    final mutedTextColor = widget.isDark ? textMutedDark : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accentPurple))
            : RefreshIndicator( // Added RefreshIndicator so you can pull-to-update stats
          onRefresh: _loadData,
          color: accentPurple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Stats",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track your productivity",
                  style: TextStyle(
                    fontSize: 15,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.isDark ? cardDark : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildTab("Overview", 0, mutedTextColor),
                      _buildTab("Tasks", 1, mutedTextColor),
                      _buildTab("Habits", 2, mutedTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: widget.isDark ? cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 12,
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.withValues(alpha: 0.1),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 12,
                                    strokeCap: StrokeCap.round,
                                    color: accentPurple,
                                  );
                                },
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${(progress * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: widget.isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  "completed",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark ? bgDark : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentTotal == 0 ? emptyStateText : "$currentPending remaining",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        isDark: widget.isDark,
                        label: "Total",
                        value: currentTotal.toString(),
                        color: const Color(0xFF6366F1),
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        isDark: widget.isDark,
                        label: "Done",
                        value: currentCompleted.toString(),
                        color: accentGreen,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        isDark: widget.isDark,
                        label: "Pending",
                        value: currentPending.toString(),
                        color: const Color(0xFFF59E0B),
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        isDark: widget.isDark,
                        label: "Focus Today",
                        value: "$todayMinutes min",
                        color: const Color(0xFF0EA5E9),
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        isDark: widget.isDark,
                        label: "All-Time Focus",
                        value: "${(totalMinutes / 60).toStringAsFixed(1)}h",
                        color: const Color(0xFFEC4899),
                        icon: Icons.insights_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.isDark,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1A132C) : Colors.white;
    final mutedTextColor = isDark ? const Color(0xFF8A849C) : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}