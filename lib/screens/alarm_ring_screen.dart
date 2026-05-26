import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'dart:ui' show ImageFilter;

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Animation/Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF3B1010), Colors.black],
                  center: Alignment.center,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.alarm_on_rounded,
                      size: 80,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      alarmSettings.notificationSettings.body.isNotEmpty
                          ? alarmSettings.notificationSettings.body
                          : "Time's up!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Snooze Button
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        await Alarm.set(
                          alarmSettings: alarmSettings.copyWith(
                            dateTime: DateTime(
                              now.year,
                              now.month,
                              now.day,
                              now.hour,
                              now.minute,
                              now.second,
                              0,
                            ).add(const Duration(minutes: 5)),
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.snooze_rounded, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text("Snooze +5m", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // Stop Button
                    GestureDetector(
                      onTap: () async {
                        await Alarm.stop(alarmSettings.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.stop_rounded, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text("Stop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
