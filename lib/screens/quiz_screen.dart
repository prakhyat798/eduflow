import 'dart:ui';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> quizData;
  final bool isDark;

  const QuizScreen({
    super.key,
    required this.quizData,
    required this.isDark,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool isAnswered = false;

  void _submitAnswer(String answer) {
    if (isAnswered) return;

    setState(() {
      selectedAnswer = answer;
      isAnswered = true;

      if (answer ==
          widget.quizData[currentIndex]['correctAnswer']) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentIndex < widget.quizData.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        isAnswered = false;
      });
    } else {
      _showScoreDialog();
    }
  }

  void _showScoreDialog() {
    final isPerfect = score == widget.quizData.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            isPerfect ? "Perfect Score! 🎉" : "Quiz Complete!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$score / ${widget.quizData.length} correct",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isPerfect
                      ? const Color(0xFF0CBF83)
                      : const Color(0xFF9147FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPerfect
                    ? "Excellent work! You nailed it."
                    : "Keep practising to improve!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9147FF),
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (context.mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to PDF screen
                }
              },
              child: const Text(
                "Done",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionData = widget.quizData[currentIndex];
    final options =
    List<String>.from(questionData['options']);

    return Scaffold(
      backgroundColor:
      widget.isDark ? const Color(0xFF080B14) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            "Question ${currentIndex + 1}/${widget.quizData.length}"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value:
              (currentIndex + 1) / widget.quizData.length,
              minHeight: 8,
              color: const Color(0xFF9147FF),
            ),
            const SizedBox(height: 30),

            Text(
              questionData['question'],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ...options.map((option) {
              bool isSelected = selectedAnswer == option;

              return GestureDetector(
                onTap: () => _submitAnswer(option),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF111827)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9147FF)
                          : Colors.grey,
                    ),
                  ),
                  child: Text(option),
                ),
              );
            }),

            const Spacer(),

            if (isAnswered)
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9147FF),
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(color: Colors.white),
                ),
              )
          ],
        ),
      ),
    );
  }
}