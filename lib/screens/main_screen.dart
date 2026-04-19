import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;

import 'home_screen.dart';
import 'stats_screen.dart';
import 'roadmap_screen.dart';
import 'focus_screen.dart';
import 'notes_screen.dart';
import 'pdf_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.isDark,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  static const Color _purple = Color(0xFF9147FF);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(toggleTheme: widget.toggleTheme, isDark: widget.isDark),
      StatsScreen(isDark: widget.isDark),
      RoadmapScreen(isDark: widget.isDark),
      FocusScreen(isDark: widget.isDark),
      NotesScreen(isDark: widget.isDark),
      PdfScreen(isDark: widget.isDark),
      HistoryScreen(isDark: widget.isDark),
    ];

    return Scaffold(
      extendBody: true, // Allows body to scroll behind the nav bar
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: widget.isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              // 🔥 Wrapping in SingleChildScrollView fixes the 7-icon overflow issue
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _nav(Icons.home_rounded, 0, "Home"),
                    const SizedBox(width: 8),
                    _nav(Icons.bar_chart_rounded, 1, "Stats"),
                    const SizedBox(width: 8),
                    _nav(Icons.route_rounded, 2, "Roadmap"),
                    const SizedBox(width: 8),
                    _nav(Icons.timer_rounded, 3, "Focus"),
                    const SizedBox(width: 8),
                    _nav(Icons.edit_note_rounded, 4, "Notes"),
                    const SizedBox(width: 8),
                    _nav(Icons.document_scanner_rounded, 5, "Scan"),
                    const SizedBox(width: 8),
                    _nav(Icons.history_rounded, 6, "History"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, int index, String label) {
    final selected = currentIndex == index;
    final mutedColor = widget.isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // 🔥 Satisfying physical click
        setState(() => currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _purple.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: selected ? [
            BoxShadow(color: _purple.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)
          ] : [],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: selected ? 1.15 : 1.0, // 🔥 Selected icon grows
          child: Icon(
            icon,
            size: 26,
            color: selected ? _purple : mutedColor,
          ),
        ),
      ),
    );
  }
}