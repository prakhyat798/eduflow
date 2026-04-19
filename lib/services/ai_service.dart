import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // ✅ HARDCODED (WORKING)
  static const String apiKey =
      "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";

  static const String baseUrl =
      "https://openrouter.ai/api/v1/chat/completions";
  static const String modelName = "openai/gpt-3.5-turbo";

  // ==========================================
  // 🔥 COMMON REQUEST FUNCTION
  // ==========================================
  static Future<String> _sendRequest(String system, String user) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": modelName,
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['choices'] == null) {
      throw Exception("API Error: ${response.body}");
    }

    return data['choices'][0]['message']['content'];
  }

  // ==========================================
  // ✅ ROADMAP
  // ==========================================
  static Future<Map<String, dynamic>> generateRoadmap(
      String goal) async {
    final content = await _sendRequest(
      """
Create a roadmap ONLY for "$goal".

Rules:
- Do NOT include unrelated tech
- Keep steps clear and practical
- No quizzes

Return ONLY JSON:
{
  "Beginner": [{"step": "..."}],
  "Intermediate": [{"step": "..."}],
  "Advanced": [{"step": "..."}]
}
""",
      "Generate roadmap",
    );

    final cleaned =
    content.replaceAll('```json', '').replaceAll('```', '').trim();

    return jsonDecode(cleaned);
  }

  // ==========================================
  // ✅ NOTES
  // ==========================================
  static Future<String> generateNotes(String topic) async {
    final content = await _sendRequest(
      """
Explain "$topic" clearly.

Structure:
- Definition
- Explanation
- Example
- Key Points

Keep it simple.
""",
      topic,
    );

    return content;
  }

  // ==========================================
  // ✅ PDF SUMMARY
  // ==========================================
  static Future<String> summarizePdfText(String text) async {
    final content = await _sendRequest(
      "Summarize this in bullet points",
      text,
    );

    return content;
  }

  // ==========================================
  // ✅ QUIZ
  // ==========================================
  static Future<List<dynamic>> generateQuiz(String topic) async {
    final content = await _sendRequest(
      """
Create 3 MCQs.

Return ONLY JSON:
[
 { "question": "...", "options": ["A","B","C","D"], "correctAnswer": "A" }
]
""",
      topic,
    );

    final cleaned =
    content.replaceAll('```json', '').replaceAll('```', '').trim();

    return jsonDecode(cleaned);
  }

  // ==========================================
  // 🔥 NEW: ASK QUESTION (FIXES YOUR ERROR)
  // ==========================================
  static Future<String> askQuestion(
      String topic, String question) async {
    final content = await _sendRequest(
      """
You are a helpful tutor.

Topic: $topic

Answer clearly, simply, and to the point.
""",
      question,
    );

    return content;
  }
}