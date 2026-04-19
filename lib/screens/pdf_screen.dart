import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';
import 'scanner_screen.dart';
import 'quiz_screen.dart';

class PdfScreen extends StatefulWidget {
  final bool isDark;
  const PdfScreen({super.key, required this.isDark});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  String _summary = "";
  String _rawText = "";
  String _fileName = "";
  bool _isLoading = false;
  bool _isGeneratingQuiz = false;

  // ── Theme tokens ────────────────────────────────────────────
  static const Color accent = Color(0xFF9147FF);
  static const Color accentSoft = Color(0x229147FF);
  static const Color danger = Color(0xFFFF4D4D);

  // ── Helpers ─────────────────────────────────────────────────
  Color get _bg => widget.isDark ? const Color(0xFF0A0616) : const Color(0xFFF3F4F8);
  Color get _card => widget.isDark ? const Color(0xFF1A132C) : Colors.white;
  Color get _text => widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _sub => widget.isDark ? Colors.white38 : Colors.black38;

  // ── Save path ───────────────────────────────────────────────
  Future<void> _savePdf(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> files = List.from(prefs.getStringList("pdf_files") ?? []);
    files.remove(path);
    files.insert(0, path);
    await prefs.setStringList("pdf_files", files);
  }

  // ── Extract + Summarise (shared logic) ──────────────────────
  Future<void> _processPath(String path) async {
    setState(() {
      _isLoading = true;
      _summary = "";
      _fileName = path.split('/').last;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      _rawText = text.length > 3000 ? text.substring(0, 3000) : text;
      final res = await AIService.summarizePdfText(_rawText);
      setState(() {
        _summary = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _summary = "Couldn't process this PDF.";
        _isLoading = false;
      });
    }
  }

  // ── Pick PDF ─────────────────────────────────────────────────
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final path = result.files.single.path!;
    await _savePdf(path);
    await _processPath(path);
  }

  // ── Generate Quiz ────────────────────────────────────────────
  Future<void> _generateQuiz() async {
    if (_rawText.isEmpty) return;
    setState(() => _isGeneratingQuiz = true);
    try {
      final quizData = await AIService.generateQuiz(_rawText);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(quizData: quizData, isDark: widget.isDark),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz generation failed.")),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingQuiz = false);
    }
  }

  // ── Delete file ──────────────────────────────────────────────
  Future<void> _deleteFile(SharedPreferences prefs, List<String> files, String path) async {
    files.remove(path);
    await prefs.setStringList("pdf_files", files);
    setState(() {});
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUploadCard(),
                    const SizedBox(height: 24),
                    if (_isLoading) _buildLoadingCard(),
                    if (!_isLoading && _summary.isNotEmpty) _buildSummaryCard(),
                    if (!_isLoading && _summary.isNotEmpty) const SizedBox(height: 16),
                    if (!_isLoading && _rawText.isNotEmpty) _buildQuizButton(),
                    const SizedBox(height: 32),
                    _buildSavedSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                "AI Summarizer",
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Upload a PDF to get an instant AI summary",
            style: TextStyle(color: _sub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Upload card ──────────────────────────────────────────────
  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickPdf,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _fileName.isEmpty ? accentSoft : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withOpacity(_fileName.isEmpty ? 0.5 : 0.25),
            width: 1.5,
          ),
        ),
        child: _fileName.isEmpty
            ? Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded, color: accent, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              "Tap to upload PDF",
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Supports .pdf files",
              style: TextStyle(color: _sub, fontSize: 12),
            ),
          ],
        )
            : Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName,
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text("Tap to change file",
                      style: TextStyle(color: _sub, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.swap_horiz_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Loading card ─────────────────────────────────────────────
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Summarising your document…",
            style: TextStyle(color: _text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text("This may take a few seconds",
              style: TextStyle(color: _sub, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                "AI Summary",
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _summary,
            style: TextStyle(
              color: _text,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz button ───────────────────────────────────────────────
  Widget _buildQuizButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingQuiz ? null : _generateQuiz,
        icon: _isGeneratingQuiz
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.quiz_rounded, size: 18),
        label: Text(_isGeneratingQuiz ? "Generating Quiz…" : "Generate Quiz"),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Saved files section ──────────────────────────────────────
  Widget _buildSavedSection() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        final files = List<String>.from(prefs.getStringList("pdf_files") ?? []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  "Saved Documents",
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (files.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${files.length}",
                      style: const TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Empty state
            if (files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded, color: _sub, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      "No documents yet",
                      style: TextStyle(color: _sub, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // File list
            ...files.map((path) {
              final name = path.split('/').last;
              final ext = name.split('.').last.toUpperCase();

              return GestureDetector(
                onTap: () async {
                  await _savePdf(path);
                  await _processPath(path);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: _fileName == name
                        ? Border.all(color: accent.withOpacity(0.5), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // File type badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            ext,
                            style: const TextStyle(
                              color: danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // File name
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Active indicator
                      if (_fileName == name)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Active",
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                      // Delete
                      GestureDetector(
                        onTap: () => _deleteFile(prefs, files, path),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: danger, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ── FAB ───────────────────────────────────────────────────────
  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScannerScreen(isDark: widget.isDark),
          ),
        ),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text(
          "Scan Notes",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}