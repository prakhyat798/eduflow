import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/streak_service.dart';
import 'dart:ui' show ImageFilter;

class FocusScreen extends StatefulWidget {
  final bool isDark;
  const FocusScreen({super.key, required this.isDark});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  int selectedMinutes = 25;
  late int seconds;
  late int initialSeconds;
  Timer? timer;

  bool isRunning = false;
  bool isFinished = false;
  bool focusFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    seconds = selectedMinutes * 60;
    initialSeconds = seconds;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isRunning && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
      _breakFocus();
    }
  }

  void _breakFocus() {
    timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      isRunning = false;
      focusFailed = true;
    });
  }

  double get progress => initialSeconds == 0 ? 0 : (1 - seconds / initialSeconds).clamp(0.0, 1.0);

  String _getTreeEmoji() {
    if (focusFailed) return "🥀";
    if (isFinished) return "🌸";
    if (!isRunning && progress == 0) return "🪴";

    if (progress < 0.33) return "🌱";
    if (progress < 0.66) return "🌿";
    return "🌳";
  }

  String formatTime() {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  void startTimer() {
    if (isRunning) return;
    HapticFeedback.mediumImpact();
    setState(() {
      isRunning = true;
      isFinished = false;
      focusFailed = false;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        t.cancel();
        timer = null;
        HapticFeedback.heavyImpact();
        setState(() { isRunning = false; isFinished = true; });
        saveSession();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    timer = null;
    HapticFeedback.lightImpact();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    timer?.cancel();
    timer = null;
    HapticFeedback.lightImpact();
    setState(() {
      seconds = selectedMinutes * 60;
      initialSeconds = seconds;
      isRunning = false;
      isFinished = false;
      focusFailed = false;
    });
  }

  void setTime(int minutes) {
    if (isRunning) return;
    HapticFeedback.lightImpact();
    setState(() {
      selectedMinutes = minutes;
      seconds = minutes * 60;
      initialSeconds = seconds;
      isFinished = false;
      focusFailed = false;
    });
  }

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    int today = prefs.getInt("today_minutes") ?? 0;
    int total = prefs.getInt("total_minutes") ?? 0;
    await prefs.setInt("today_minutes", today + selectedMinutes);
    await prefs.setInt("total_minutes", total + selectedMinutes);
    await StreakService.recordCompletion();
  }

  void _showCustomTimeDialog() {
    if (isRunning) return;
    int customValue = selectedMinutes;
    bool isHours = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Text("Custom Timer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: isHours ? "Hours" : "Minutes",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) customValue = parsed;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setStateDialog(() => isHours = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isHours ? const Color(0xFF7C3AED).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !isHours ? const Color(0xFFA78BFA) : Colors.transparent),
                        ),
                        child: Text(
                            "Minutes",
                            style: TextStyle(
                                color: !isHours ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w600
                            )
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setStateDialog(() => isHours = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isHours ? const Color(0xFF7C3AED).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isHours ? const Color(0xFFA78BFA) : Colors.transparent),
                        ),
                        child: Text(
                            "Hours",
                            style: TextStyle(
                                color: isHours ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w600
                            )
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setTime(isHours ? customValue * 60 : customValue);
                  Navigator.pop(context);
                },
                child: const Text("Set"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/focus_bg.jpg', fit: BoxFit.cover),
          ),

          if (focusFailed)
            Positioned.fill(
              child: Container(color: Colors.redAccent.withValues(alpha: 0.15)),
            ),

          if (!focusFailed)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Focus Mode",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        focusFailed
                            ? "You left the app! Tree withered."
                            : isFinished
                            ? "Session complete! Great work"
                            : isRunning
                            ? "Stay in the zone..."
                            : "Ready when you are",
                        style: TextStyle(
                          color: focusFailed
                              ? Colors.redAccent
                              : isFinished
                              ? const Color(0xFFA78BFA)
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          fontWeight: focusFailed ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _chip(15), _chip(25), _chip(45), _chip(60),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: _showCustomTimeDialog,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.6)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_rounded, color: Color(0xFFA78BFA), size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                      "Custom",
                                      style: TextStyle(
                                          color: Color(0xFFA78BFA),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13
                                      )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: focusFailed
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1)
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🔥 THE FIX: Wrapping the tree and time in an Expanded so it can shrink!
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 500),
                                        transitionBuilder: (Widget child, Animation<double> animation) {
                                          return ScaleTransition(scale: animation, child: child);
                                        },
                                        child: Text(
                                          _getTreeEmoji(),
                                          key: ValueKey<String>(_getTreeEmoji()),
                                          style: const TextStyle(fontSize: 38),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 🔥 The FittedBox automatically scales the font down if it's too long
                                      Expanded(
                                        child: FittedBox(
                                          alignment: Alignment.centerLeft,
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            formatTime(),
                                            style: TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w800,
                                              color: focusFailed ? Colors.redAccent : Colors.white,
                                              letterSpacing: -2,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16), // A little breathing room before the right column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$selectedMinutes min",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "${(progress * 100).toInt()}% done",
                                      style: TextStyle(
                                        color: focusFailed ? Colors.redAccent : const Color(0xFFA78BFA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Stack(
                              children: [
                                Container(
                                  height: 5,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 5,
                                  width: (MediaQuery.of(context).size.width - 84) * progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: focusFailed
                                          ? [Colors.redAccent, Colors.red]
                                          : [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (focusFailed ? Colors.redAccent : const Color(0xFF7C3AED)).withValues(alpha: 0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                GestureDetector(
                                  onTap: isRunning ? pauseTimer : startTimer,
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: focusFailed
                                            ? [Colors.redAccent, Colors.red]
                                            : [const Color(0xFF7C3AED), const Color(0xFF9F67FA)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (focusFailed ? Colors.redAccent : const Color(0xFF7C3AED)).withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isRunning ? Icons.pause_rounded : (focusFailed ? Icons.replay_rounded : Icons.play_arrow_rounded),
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: resetTimer,
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                                const Spacer(),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isRunning
                                            ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isRunning
                                              ? const Color(0xFFA78BFA).withValues(alpha: 0.5)
                                              : Colors.white.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: focusFailed
                                                  ? Colors.redAccent
                                                  : isFinished
                                                  ? const Color(0xFF10B981)
                                                  : isRunning
                                                  ? const Color(0xFFA78BFA)
                                                  : Colors.white.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            focusFailed ? "Failed" : isFinished ? "Done" : isRunning ? "Focusing" : "Paused",
                                            style: TextStyle(
                                              color: focusFailed
                                                  ? Colors.redAccent
                                                  : isRunning
                                                  ? const Color(0xFFA78BFA)
                                                  : Colors.white.withValues(alpha: 0.6),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 65),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int m) {
    final isSelected = selectedMinutes == m;
    return GestureDetector(
      onTap: () => setTime(m),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFA78BFA)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              "$m min",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}