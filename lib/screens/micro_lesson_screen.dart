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
  // ── Palette ──────────────────────────────────────────────────
  static const Color _accent = Color(0xFF9147FF);
  static const Color _cardDark = Color(0xFF111827);
  static const Color _bgDark = Color(0xFF080B14);

  // ── State ────────────────────────────────────────────────────
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 0 = input, 1 = loading, 2 = notes shown, 3 = error
  int _step = 0;
  String _notes = '';
  String _answer = '';
  bool _isAsking = false;
  bool _hasAnswered = false;

  // ── Theme helpers ────────────────────────────────────────────
  Color get bg => widget.isDark ? _bgDark : Colors.grey[50]!;
  Color get card => widget.isDark ? _cardDark : Colors.white;
  Color get textColor => widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get mutedText => widget.isDark ? Colors.white38 : Colors.black38;
  Color get inputFill => widget.isDark ? _cardDark : Colors.white;

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      _topicController.text = widget.topic!;
      _generateNotes();
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Generate notes ───────────────────────────────────────────
  Future<void> _generateNotes() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _step = 1;
      _answer = '';
      _hasAnswered = false;
    });

    try {
      final result = await AIService.generateNotes(topic);
      await _saveToHistory(topic, result);
      if (!mounted) return;
      setState(() {
        _notes = result;
        _step = 2;
      });
      // Scroll to top after notes load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _step = 3);
    }
  }

  // ── Save to history ──────────────────────────────────────────
  Future<void> _saveToHistory(String topic, String notes) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> raw = prefs.getStringList('learning_history') ?? [];
    List<Map<String, dynamic>> history =
        raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    history.removeWhere((e) => e['topic'] == topic);
    history.insert(0, {
      'topic': topic,
      'notes': notes,
      'time': DateTime.now().toIso8601String(),
    });
    await prefs.setStringList(
        'learning_history', history.map((e) => jsonEncode(e)).toList());
  }

  // ── Ask AI a question (uses askQuestion — context-aware) ─────
  Future<void> _askQuestion() async {
    final q = _questionController.text.trim();
    if (q.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isAsking = true;
      _hasAnswered = false;
      _answer = '';
    });

    try {
      // ✅ FIXED: use askQuestion() not generateNotes()
      final result =
          await AIService.askQuestion(_topicController.text.trim(), q);
      if (!mounted) return;
      setState(() {
        _answer = result;
        _isAsking = false;
        _hasAnswered = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAsking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get answer. Try again.')),
      );
    }
  }

  // ── Mark step as learned ─────────────────────────────────────
  Future<void> _markAsLearned() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('current_roadmap');

    if (raw != null) {
      final data = jsonDecode(raw);
      final allSteps = [
        ...data['Beginner'],
        ...data['Intermediate'],
        ...data['Advanced'],
      ];
      int index = prefs.getInt('current_step_index') ?? 0;
      if (index < allSteps.length) {
        await prefs.setInt('current_step_index', index + 1);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _topicController.text.isNotEmpty ? _topicController.text : 'Micro Lesson',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildInputState();
      case 1:
        return _buildLoadingState();
      case 2:
        return _buildNotesState();
      case 3:
        return _buildErrorState();
      default:
        return _buildInputState();
    }
  }

  // ── Step 0: Input ────────────────────────────────────────────
  Widget _buildInputState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'What do you\nwant to learn?',
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a topic and AI will generate clear notes for you.',
            style: TextStyle(color: mutedText, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _topicController,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Binary Search Trees',
                hintStyle: TextStyle(color: mutedText),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.lightbulb_outline_rounded, color: _accent, size: 20),
              ),
              onSubmitted: (_) => _generateNotes(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateNotes,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text(
                'Generate Notes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Loading ──────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: _accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating your notes…',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This takes a few seconds',
            style: TextStyle(color: mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Error ────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to generate notes',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedText, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateNotes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Notes ────────────────────────────────────────────
  Widget _buildNotesState() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _accent.withValues(alpha: 0.15)),
              boxShadow: widget.isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: _accent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI Notes',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Regenerate button
                    GestureDetector(
                      onTap: _generateNotes,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: _accent, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Redo',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _notes,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ask AI section
          Text(
            'Ask a question',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about this topic…',
                      hintStyle: TextStyle(color: mutedText, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _askQuestion(),
                  ),
                ),
                GestureDetector(
                  onTap: _isAsking ? null : _askQuestion,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isAsking
                          ? _accent.withValues(alpha: 0.3)
                          : _accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isAsking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Answer card
          if (_hasAnswered && _answer.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: _accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'AI Answer',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _answer,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Mark as learned
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAsLearned,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'Mark as Learned',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0CBF83),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}