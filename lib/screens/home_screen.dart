import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import '../models/item.dart';
import '../services/reminder_service.dart';
import 'micro_lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> tasks = [];
  List<Item> habits = [];
  List<Map<String, dynamic>> reminders = [];
  int streak = 0;
  bool _isLoading = true;

  // ── Palette ──────────────────────────────────────────────────
  static const Color _accent = Color(0xFF9147FF);
  static const Color _cardDark = Color(0xFF150F27);
  static const Color _bgDark = Color(0xFF0A0616);

  // ── Theme helpers ────────────────────────────────────────────
  Color get bg => widget.isDark ? _bgDark : const Color(0xFFF3F4F8);
  Color get cardBg => widget.isDark ? _cardDark : Colors.white;
  Color get textColor => widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get mutedText => widget.isDark ? const Color(0xFF6B6480) : Colors.black38;
  Color get divider => widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTasks = prefs.getString('tasks');
    final rawHabits = prefs.getString('habits');
    final rawReminders = prefs.getString('reminders');
    setState(() {
      streak = prefs.getInt('streak') ?? 0;
      if (rawTasks != null) {
        tasks = (jsonDecode(rawTasks) as List).map((e) => Item.fromJson(e)).toList();
      }
      if (rawHabits != null) {
        habits = (jsonDecode(rawHabits) as List).map((e) => Item.fromJson(e)).toList();
      }
      if (rawReminders != null) {
        reminders = List<Map<String, dynamic>>.from(jsonDecode(rawReminders));
      }
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await prefs.setString('habits', jsonEncode(habits.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminders', jsonEncode(reminders));
  }

  Future<Map<String, dynamic>?> getProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("current_roadmap");
    final index = prefs.getInt("current_step_index") ?? 0;
    if (raw == null) return null;
    final data = jsonDecode(raw);
    final allSteps = [...data['Beginner'], ...data['Intermediate'], ...data['Advanced']];
    if (allSteps.isEmpty) return null;
    return {
      "step": index < allSteps.length ? allSteps[index] : null,
      "current": index + 1,
      "total": allSteps.length,
      "progress": (index / allSteps.length).clamp(0.0, 1.0),
    };
  }

  // ── FIX: Generate a safe 32-bit notification ID ──────────────
  // DateTime.millisecondsSinceEpoch exceeds 32-bit int limit,
  // which crashes flutter_local_notifications. Modulo keeps it safe.
  int _generate32BitId() {
    return DateTime.now().millisecondsSinceEpoch % 2147483647;
  }

  // ── Add task/habit dialog ────────────────────────────────────
  void _showAddDialog() {
    final controller = TextEditingController();
    bool isHabit = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: _accent.withValues(alpha: 0.2)),
            ),
            title: Text(
              isHabit ? "New Habit" : "New Task",
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ToggleButtons(
                    isSelected: [!isHabit, isHabit],
                    onPressed: (i) => setStateDialog(() => isHabit = i == 1),
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    color: mutedText,
                    fillColor: _accent,
                    renderBorder: false,
                    constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                    children: const [
                      Text("Task", style: TextStyle(fontWeight: FontWeight.w700)),
                      Text("Habit", style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: isHabit ? "e.g., Read for 20 mins" : "e.g., Finish homework",
                    hintStyle: TextStyle(color: mutedText),
                    filled: true,
                    fillColor: widget.isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: mutedText, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    final item = Item(title: text);
                    if (isHabit) {
                      habits.insert(0, item);
                    } else {
                      tasks.insert(0, item);
                    }
                  });
                  _save();
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add reminder dialog ──────────────────────────────────────
  void _addReminder() {
    final controller = TextEditingController();
    TimeOfDay? picked;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_rounded, color: Colors.redAccent, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  "New Reminder",
                  style: TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 17),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "e.g., Review flashcards",
                    hintStyle: TextStyle(color: mutedText),
                    filled: true,
                    fillColor: widget.isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setStateDialog(() => picked = time);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: picked != null
                          ? Colors.red.withValues(alpha: 0.08)
                          : (widget.isDark ? Colors.black12 : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: picked != null ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: picked != null ? Colors.redAccent : mutedText,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          picked != null ? picked!.format(dialogCtx) : "Pick a time",
                          style: TextStyle(
                            color: picked != null ? textColor : mutedText,
                            fontWeight: picked != null ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text("Cancel", style: TextStyle(color: mutedText, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (picked == null || text.isEmpty) return;

                  Navigator.pop(dialogCtx);

                  final now = DateTime.now();
                  final scheduledTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    picked!.hour,
                    picked!.minute,
                  );

                  // ── FIX: 32-bit safe ID ──────────────────
                  final int id = _generate32BitId();

                  setState(() {
                    reminders.insert(0, {
                      "id": id,
                      "text": text,
                      "time": scheduledTime.toIso8601String(),
                    });
                  });
                  await ReminderService.scheduleReminder(
                    id: id,
                    title: "EduFlow Reminder",
                    body: text,
                    time: scheduledTime,
                  );
                  await _saveReminders();
                },
                child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReminder(int id) async {
    try {
      await ReminderService.cancelReminder(id);
    } catch (_) {
      // Safely ignore cancel errors for any old invalid IDs
    }
    setState(() => reminders.removeWhere((r) => (r['id'] as num).toInt() == id));
    await _saveReminders();
  }

  // ── Quote card ───────────────────────────────────────────────
  Widget _buildQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _accent.withValues(alpha: 0.12)),
          boxShadow: widget.isDark
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -16,
              child: Icon(Icons.format_quote_rounded, size: 72, color: _accent.withValues(alpha: 0.05)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: _accent.withValues(alpha: 0.8), size: 18),
                const SizedBox(height: 14),
                Text(
                  '"Small disciplines lead to great achievements."',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: textColor.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "— John C. Maxwell",
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reminders section — swipe left to delete ─────────────────
  Widget _buildReminders() {
    if (reminders.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.alarm_rounded, color: Colors.redAccent, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                "Reminders",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${reminders.length}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "swipe to delete",
                style: TextStyle(color: mutedText, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reminders.asMap().entries.map((entry) {
            final r = entry.value;
            final time = DateTime.tryParse(r['time'] ?? '');
            final formattedTime = time != null
                ? TimeOfDay.fromDateTime(time).format(context)
                : '';
            final int reminderId = (r['id'] as num).toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                // ValueKey ensures each item has a unique key for Flutter's diffing
                key: ValueKey(reminderId),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteReminder(reminderId),
                // Red delete background revealed on swipe
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                      SizedBox(height: 4),
                      Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.alarm_rounded, color: Colors.redAccent, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['text'] ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (formattedTime.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Swipe hint icon
                      Icon(Icons.swipe_left_alt_rounded, color: mutedText, size: 16),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Task / Habit list ────────────────────────────────────────
  Widget _buildItemList(String title, List<Item> items, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${items.length}",
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divider),
              ),
              child: Column(
                children: [
                  Icon(icon, color: mutedText.withValues(alpha: 0.4), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    "No ${title.toLowerCase()} yet",
                    style: TextStyle(color: mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isDone = item.isDone;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isDone ? color.withValues(alpha: 0.06) : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDone ? color.withValues(alpha: 0.25) : divider,
                  width: 1.2,
                ),
                boxShadow: isDone || widget.isDark
                    ? []
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => item.isDone = !item.isDone);
                      _save();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? color : mutedText.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isDone ? mutedText : textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: mutedText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => items.removeAt(i));
                      _save();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 15),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Progress card ────────────────────────────────────────────
  Widget _buildProgressCard() {
    return FutureBuilder(
      future: getProgressData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Start Your Journey",
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text("Create a roadmap to begin",
                            style: TextStyle(color: mutedText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final step = data["step"];

        if (step == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Roadmap Complete! 🎉",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text("Set a new goal to keep growing.",
                            style: TextStyle(color: mutedText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MicroLessonScreen(topic: step['step'], isDark: widget.isDark),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF9F5FFF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "DAY ${data['current']} OF ${data['total']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    step['step'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: data['progress'],
                            minHeight: 5,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(data['progress'] * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: FloatingActionButton.extended(
            backgroundColor: _accent,
            onPressed: _showAddDialog,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              "Add Goal",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EduFlow",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("🔥", style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                "$streak Day Streak",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: divider),
                          ),
                          child: IconButton(
                            onPressed: _addReminder,
                            icon: Icon(Icons.alarm_add_rounded, color: textColor, size: 20),
                            tooltip: "Add Reminder",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: divider),
                          ),
                          child: IconButton(
                            onPressed: widget.toggleTheme,
                            icon: Icon(
                              widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: textColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Progress card ────────────────────────
              _buildProgressCard(),

              // ── Quote ────────────────────────────────
              _buildQuote(),
              const SizedBox(height: 28),

              // ── Reminders ────────────────────────────
              _buildReminders(),
              if (reminders.isNotEmpty) const SizedBox(height: 20),

              // ── Tasks ────────────────────────────────
              _buildItemList("Tasks", tasks, Icons.task_alt_rounded, _accent),
              const SizedBox(height: 20),

              // ── Habits ───────────────────────────────
              _buildItemList("Habits", habits, Icons.repeat_rounded, Colors.orange),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}