import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  final bool isDark;
  const ScannerScreen({super.key, required this.isDark});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<String> images = [];
  List<bool> selected = [];
  bool isLoading = false;

  bool get allSelected => selected.every((s) => s);
  int get selectedCount => selected.where((s) => s).length;

  Future<void> scanDocs() async {
    try {
      final result = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: true,
      );
      if (result == null || result.isEmpty) return;
      setState(() {
        images.addAll(result);
        selected.addAll(List.generate(result.length, (_) => true));
      });
    } catch (e) {
      debugPrint("Scan error: $e");
    }
  }

  void toggleSelectAll() {
    final newVal = !allSelected;
    setState(() => selected = List.generate(images.length, (_) => newVal));
  }

  Future<void> createPdf() async {
    final selectedImages = [
      for (int i = 0; i < images.length; i++)
        if (selected[i]) images[i]
    ];

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one page")),
      );
      return;
    }

    setState(() => isLoading = true);

    final pdf = pw.Document();
    for (var path in selectedImages) {
      final img = pw.MemoryImage(File(path).readAsBytesSync());
      pdf.addPage(
        pw.Page(build: (ctx) => pw.Center(child: pw.Image(img))),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf";
    await File(filePath).writeAsBytes(await pdf.save());

    final prefs = await SharedPreferences.getInstance();
    final files =
    List<String>.from(prefs.getStringList("pdf_files") ?? []);
    files.insert(0, filePath);
    await prefs.setStringList("pdf_files", files);

    setState(() => isLoading = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ PDF saved!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _deleteImage(int i) {
    setState(() {
      images.removeAt(i);
      selected.removeAt(i);
    });
  }

  void _viewFullImage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF0A0616) : const Color(0xFFF5F5F7);
    final cardBg = isDark ? const Color(0xFF1A1030) : Colors.white;
    final accent = const Color(0xFF6C63FF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? Colors.white54 : Colors.black38;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Document Scanner",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (images.isNotEmpty)
            TextButton(
              onPressed: toggleSelectAll,
              child: Text(
                allSelected ? "Deselect All" : "Select All",
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Top info bar ──────────────────────────────────────
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$selectedCount / ${images.length} selected",
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      images.clear();
                      selected.clear();
                    }),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: const Text(
                      "Clear all",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ── Page Grid ─────────────────────────────────────────
          Expanded(
            child: images.isEmpty
                ? _buildEmptyState(accent, textSub)
                : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final img = images.removeAt(oldIndex);
                  final sel = selected.removeAt(oldIndex);
                  images.insert(newIndex, img);
                  selected.insert(newIndex, sel);
                });
              },
              itemCount: images.length,
              itemBuilder: (context, i) {
                return _PageCard(
                  key: ValueKey(images[i]),
                  index: i,
                  path: images[i],
                  isSelected: selected[i],
                  isDark: isDark,
                  cardBg: cardBg,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSub: textSub,
                  onTap: () =>
                      setState(() => selected[i] = !selected[i]),
                  onDelete: () => _deleteImage(i),
                  onView: () => _viewFullImage(images[i]),
                );
              },
            ),
          ),

          // ── Bottom Actions ────────────────────────────────────
          _buildBottomBar(accent, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accent, Color textSub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.document_scanner_outlined,
                size: 52, color: accent.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Text(
            "No pages scanned yet",
            style: TextStyle(
              color: textSub,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the button below to start scanning",
            style: TextStyle(color: textSub.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF110D20) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Scan / Add more
          Expanded(
            child: OutlinedButton.icon(
              onPressed: scanDocs,
              icon: const Icon(Icons.add, size: 18),
              label: Text(images.isEmpty ? "Scan" : "Add Pages"),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(width: 12),
            // Create PDF
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : createPdf,
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(
                  isLoading
                      ? "Saving..."
                      : "Save PDF ($selectedCount pages)",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Page Card Widget ──────────────────────────────────────────────────────────

class _PageCard extends StatelessWidget {
  final int index;
  final String path;
  final bool isSelected;
  final bool isDark;
  final Color cardBg, accent, textPrimary, textSub;
  final VoidCallback onTap, onDelete, onView;

  const _PageCard({
    required super.key,
    required this.index,
    required this.path,
    required this.isSelected,
    required this.isDark,
    required this.cardBg,
    required this.accent,
    required this.textPrimary,
    required this.textSub,
    required this.onTap,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: Image.file(
                File(path),
                width: 90,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Page ${index + 1}",
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? "Included in PDF" : "Excluded from PDF",
                    style: TextStyle(
                      color: isSelected ? accent : textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: onView,
                  icon: Icon(Icons.open_in_full, size: 18, color: textSub),
                  tooltip: "View",
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  tooltip: "Delete",
                ),
              ],
            ),

            // Drag handle (for reorder)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle, color: textSub, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}