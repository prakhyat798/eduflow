import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'micro_lesson_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool isDark;
  const HistoryScreen({super.key, required this.isDark});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _purple = Color(0xFF9147FF);

  String searchQuery = "";

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList("learning_history") ?? [];

    final decoded = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    // 🔥 ADD TAGS (auto)
    for (var item in decoded) {
      if (item['tags'] == null) {
        final topic = (item['topic'] ?? "").toString();
        item['tags'] = [topic.split(" ").first];
      }
    }

    return decoded;
  }

  List<Map<String, dynamic>> getRelated(
      List<Map<String, dynamic>> all, String topic) {
    return all
        .where((item) =>
        item['topic'].toLowerCase().contains(topic.toLowerCase()))
        .take(3)
        .toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = {
      'Today': <Map<String, dynamic>>[],
      'Yesterday': <Map<String, dynamic>>[],
      'Earlier': <Map<String, dynamic>>[],
    };

    for (final item in history) {
      final dt = DateTime.tryParse(item['time'] ?? '');
      if (dt == null) {
        grouped['Earlier']!.add(item);
        continue;
      }

      final day = DateTime(dt.year, dt.month, dt.day);

      if (day == today) {
        grouped['Today']!.add(item);
      } else if (day == yesterday) {
        grouped['Yesterday']!.add(item);
      } else {
        grouped['Earlier']!.add(item);
      }
    }

    return grouped;
  }

  String _formatDate(String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) {
      return isoTime.length >= 10 ? isoTime.substring(0, 10) : isoTime;
    }
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Color _iconBg(int index) {
    const colors = [
      Color(0xFF9147FF),
      Color(0xFF0CBF83),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length].withValues(alpha: 0.15);
  }

  Color _iconColor(int index) {
    const colors = [
      Color(0xFFA78BFA),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFF60A5FA),
      Color(0xFFF87171),
    ];
    return colors[index % colors.length];
  }

  IconData _iconData(int index) {
    const icons = [
      Icons.psychology_outlined,
      Icons.eco_outlined,
      Icons.menu_book_outlined,
      Icons.bolt_outlined,
      Icons.bar_chart_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getHistory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _purple),
              );
            }

            List<Map<String, dynamic>> history = snapshot.data!;

            // 🔥 SEARCH FILTER
            if (searchQuery.isNotEmpty) {
              history = history
                  .where((item) => (item['topic'] ?? "")
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
                  .toList();
            }

            final grouped = _groupByDate(history);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
                  child: Text(
                    'Learning History',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),

                /// 🔥 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (val) {
                      setState(() => searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: history.isEmpty
                      ? Center(
                    child: Text(
                      'No results',
                      style: TextStyle(color: textColor),
                    ),
                  )
                      : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final section
                      in ['Today', 'Yesterday', 'Earlier'])
                        if (grouped[section]!.isNotEmpty) ...[
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              section,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          ...grouped[section]!.map((item) {
                            final index = history.indexOf(item);
                            final tags = item['tags'] as List;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MicroLessonScreen(
                                                topic: item['topic'],
                                                isDark: widget.isDark,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _iconBg(index),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _iconData(index),
                                            color: _iconColor(index),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['topic'] ?? '',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(
                                                    item['time'] ?? ''),
                                                style: TextStyle(
                                                  color: textColor
                                                      .withValues(
                                                      alpha: 0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 🔥 TAGS
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: tags
                                        .map((tag) => Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple
                                            .withValues(
                                            alpha: 0.2),
                                        borderRadius:
                                        BorderRadius.circular(
                                            6),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                            fontSize: 10),
                                      ),
                                    ))
                                        .toList(),
                                  ),

                                  /// 🔥 RELATED NOTES
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (_) {
                                      final related = getRelated(
                                          history, item['topic']);

                                      return Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: related
                                            .map((r) => Text(
                                          "• ${r['topic']}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textColor
                                                .withValues(
                                                alpha: 0.5),
                                          ),
                                        ))
                                            .toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}