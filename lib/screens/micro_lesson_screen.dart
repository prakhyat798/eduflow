import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import 'dart:convert';

class MicroLessonScreen extends StatefulWidget {
  final bool isDark;
  final String? topic;

  const MicroLessonScreen({
    super.key,
    required this.isDark,
    this.topic,
  });

  @override
  State<MicroLessonScreen> createState() => _MicroLessonScreenState();
}

class _MicroLessonScreenState extends State<MicroLessonScreen> {
  static const Color _accentPurple = Color(0xFF9147FF);
  static const Color _cardDark = Color(0xFF1A132C);
  static const Color _bgDark = Color(0xFF0A0616);

  final TextEditingController _topicController = TextEditingController();

  int _step = 0;
  String _notes = "";

  String _question = "";
  String _answer = "";
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();

    if (widget.topic != null) {
      _topicController.text = widget.topic!;
      _generateNotes();
    }
  }

  Future<void> _generateNotes() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() => _step = 1);

    try {
      final result = await AIService.generateNotes(topic);

      await _saveToHistory(topic, result);

      setState(() {
        _notes = result;
        _step = 2;
      });
    } catch (e) {
      setState(() => _step = 0);
    }
  }

  Future<void> _saveToHistory(String topic, String notes) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> raw = prefs.getStringList("learning_history") ?? [];

    List<Map<String, dynamic>> history =
    raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    history.removeWhere((e) => e['topic'] == topic);

    history.insert(0, {
      "topic": topic,
      "notes": notes,
      "time": DateTime.now().toIso8601String(),
    });

    final updated = history.map((e) => jsonEncode(e)).toList();

    await prefs.setStringList("learning_history", updated);
  }

  /// 🔥 UPGRADED (CONTEXT-AWARE AI)
  Future<void> _askQuestion() async {
    if (_question.trim().isEmpty) return;

    setState(() => _isAsking = true);

    final prompt = """
You are a helpful tutor.

Topic: ${_topicController.text}

Notes:
$_notes

User Question:
$_question

Explain clearly and simply based ONLY on the notes.
""";

    final result = await AIService.generateNotes(prompt);

    if (!mounted) return;

    setState(() {
      _answer = result;
      _isAsking = false;
    });
  }

  Future<void> _markAsLearned() async {
    final prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt("current_step_index") ?? 0;

    final raw = prefs.getString("current_roadmap");

    if (raw != null) {
      final data = jsonDecode(raw);

      final allSteps = [
        ...data['Beginner'],
        ...data['Intermediate'],
        ...data['Advanced'],
      ];

      if (index < allSteps.length) {
        await prefs.setInt("current_step_index", index + 1);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _bgDark : Colors.grey[50];
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_step == 0) ...[
                TextField(
                  controller: _topicController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Enter topic...",
                    filled: true,
                    fillColor: widget.isDark ? _cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generateNotes,
                  child: const Text("Generate Notes"),
                ),
              ],

              if (_step == 1)
                const Center(child: CircularProgressIndicator()),

              if (_step == 2) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.isDark ? _cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _notes,
                    style: TextStyle(color: textColor, height: 1.6),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  onChanged: (val) => _question = val,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Ask anything...",
                    filled: true,
                    fillColor: widget.isDark ? _cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _askQuestion,
                  child: const Text("Ask AI"),
                ),

                if (_isAsking)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),

                if (_answer.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.black26
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_answer, style: TextStyle(color: textColor)),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPurple,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: _markAsLearned,
                    child: const Text("Mark as Learned"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}