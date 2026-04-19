import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/ai_service.dart';
import 'micro_lesson_screen.dart';

class RoadmapScreen extends StatefulWidget {
  final bool isDark;
  const RoadmapScreen({super.key, required this.isDark});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final TextEditingController _controller = TextEditingController();

  Map<String, dynamic>? currentRoadmap;
  String currentGoal = "";
  List<Map<String, dynamic>> history = [];
  Map<String, int?> userAnswers = {};

  bool isLoading = false;
  String? error;

  // 🔥 Dynamic Theme Getters (Matches Home Screen)
  static const Color _accentPurple = Color(0xFF9147FF);
  Color get bg => widget.isDark ? const Color(0xFF0A0616) : Colors.grey[50]!;
  Color get cardBg => widget.isDark ? const Color(0xFF1A132C) : Colors.white;
  Color get textColor => widget.isDark ? Colors.white : Colors.black87;
  Color get mutedText => widget.isDark ? const Color(0xFF8A849C) : Colors.black54;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('roadmap_history');
    if (data != null) {
      setState(() {
        history = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roadmap_history', jsonEncode(history));
  }

  Future<void> _generateRoadmap() async {
    final goal = _controller.text.trim();
    if (goal.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      error = null;
      currentRoadmap = null;
      currentGoal = goal;
      userAnswers.clear();
    });

    try {
      final roadmapData = await AIService.generateRoadmap(goal);

      /// 🔥 SYSTEM SAVE (IMPORTANT)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("current_goal", goal);
      await prefs.setString("current_roadmap", jsonEncode(roadmapData));
      await prefs.setInt("current_step_index", 0);

      setState(() {
        currentRoadmap = roadmapData;
        isLoading = false;
        history.insert(0, {
          "goal": goal,
          "roadmap": roadmapData,
          "date": DateTime.now().toIso8601String(),
        });
      });

      await _saveHistory();
      _controller.clear();
    } catch (e) {
      setState(() {
        error = "Couldn't generate roadmap. Check API key.";
        isLoading = false;
      });
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: mutedText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _accentPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_rounded, color: _accentPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("Roadmap History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No saved roadmaps yet.", style: TextStyle(color: mutedText))),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => Divider(color: mutedText.withOpacity(0.1), height: 1),
                  itemBuilder: (context, i) {
                    final item = history[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.route_rounded, color: _accentPurple, size: 18),
                      ),
                      title: Text(item['goal'], style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: mutedText.withOpacity(0.5)),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString("current_goal", item['goal']);
                        await prefs.setString("current_roadmap", jsonEncode(item['roadmap']));
                        await prefs.setInt("current_step_index", 0);

                        setState(() {
                          currentGoal = item['goal'];
                          currentRoadmap = item['roadmap'];
                          userAnswers.clear();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseSection(String title, List<dynamic> steps, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: color.withOpacity(0.2))),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            int idx = entry.key;
            var data = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
                boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text("${idx + 1}", style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14))),
                  ),
                  title: Text(data['step'], style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  iconColor: mutedText,
                  collapsedIconColor: mutedText,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: mutedText.withOpacity(0.1)),
                          const SizedBox(height: 12),

                          /// 🔥 BEAUTIFIED ADD BUTTON TO START LESSON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MicroLessonScreen(
                                      topic: data['step'],
                                      isDark: widget.isDark,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.play_circle_fill_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text("Start Micro-Lesson", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Skill Roadmap", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1)),
                      const SizedBox(height: 4),
                      Text("AI-Powered Learning Paths", style: TextStyle(fontSize: 14, color: mutedText, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: mutedText.withOpacity(0.2))),
                    child: IconButton(
                      onPressed: _showHistorySheet,
                      icon: Icon(Icons.history_rounded, color: textColor),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// BEAUTIFIED INPUT BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accentPurple.withOpacity(0.2)),
                  boxShadow: widget.isDark ? [] : [BoxShadow(color: _accentPurple.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "What do you want to master?",
                          hintStyle: TextStyle(color: mutedText),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _generateRoadmap(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _generateRoadmap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _accentPurple, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// RESULTS VIEW
            Expanded(
              child: isLoading
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _accentPurple),
                    const SizedBox(height: 16),
                    Text("Generating your path...", style: TextStyle(color: mutedText, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
                  : currentRoadmap == null
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, size: 80, color: _accentPurple.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    Text("Enter a skill above to begin.", style: TextStyle(color: mutedText, fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                children: [
                  /// GOAL PILL
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentPurple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _accentPurple.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.flag_rounded, color: _accentPurple, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("CURRENT GOAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _accentPurple, letterSpacing: 1)),
                              const SizedBox(height: 2),
                              Text(currentGoal, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (currentRoadmap!.containsKey('Beginner'))
                    _buildPhaseSection("Beginner", currentRoadmap!['Beginner'], const Color(0xFF0CBF83)),

                  if (currentRoadmap!.containsKey('Intermediate'))
                    _buildPhaseSection("Intermediate", currentRoadmap!['Intermediate'], const Color(0xFFF59E0B)),

                  if (currentRoadmap!.containsKey('Advanced'))
                    _buildPhaseSection("Advanced", currentRoadmap!['Advanced'], const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}