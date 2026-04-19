import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class NotesScreen extends StatefulWidget {
  final bool isDark;
  const NotesScreen({super.key, required this.isDark});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> notes = [];
  bool _isLoading = true;

  final Color bgDark = const Color(0xFF0A0616);
  final Color cardDark = const Color(0xFF1A132C);
  final Color accentPurple = const Color(0xFF9147FF);
  final Color textMutedDark = const Color(0xFF8A849C);

  final List<Color> noteColors = [
    const Color(0xFF1E293B),
    const Color(0xFF312E81),
    const Color(0xFF581C87),
    const Color(0xFF701A75),
    const Color(0xFF4C1D95),
    const Color(0xFF1E3A8A),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('sticky_notes');
    if (data != null) {
      setState(() {
        notes = List<Map<String, dynamic>>.from(jsonDecode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sticky_notes', jsonEncode(notes));
  }

  void _showNoteDialog({Map<String, dynamic>? note, int? index}) {
    TextEditingController titleController =
    TextEditingController(text: note?['title'] ?? "");
    TextEditingController contentController =
    TextEditingController(text: note?['content'] ?? "");
    int selectedColorIndex = note?['colorIndex'] ?? 0;

    stt.SpeechToText speech = stt.SpeechToText();
    bool isListening = false;
    String baseText = contentController.text;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void listen() async {
            if (!isListening) {
              var status = await Permission.microphone.request();
              if (status.isGranted) {
                bool available = await speech.initialize();
                if (available) {
                  setStateDialog(() {
                    isListening = true;
                    baseText = contentController.text;
                    if (baseText.isNotEmpty && !baseText.endsWith(" ")) {
                      baseText += " ";
                    }
                  });

                  speech.listen(
                    onResult: (result) {
                      setStateDialog(() {
                        contentController.text =
                            baseText + result.recognizedWords;
                        contentController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: contentController.text.length));
                      });
                    },
                  );
                }
              }
            } else {
              setStateDialog(() => isListening = false);
              speech.stop();
            }
          }

          return AlertDialog(
            backgroundColor: widget.isDark ? cardDark : Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              note == null ? "New Note" : "Edit Note",
              style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Title",
                      hintStyle: TextStyle(color: textMutedDark),
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    style: TextStyle(
                        color:
                        widget.isDark ? Colors.white70 : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Write or speak your idea...",
                      hintStyle: TextStyle(color: textMutedDark),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: noteColors.length,
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () =>
                                  setStateDialog(() => selectedColorIndex = i),
                              child: Container(
                                width: 35,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: noteColors[i],
                                  shape: BoxShape.circle,
                                  border: selectedColorIndex == i
                                      ? Border.all(
                                      color: Colors.white, width: 2)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: listen,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isListening
                                ? Colors.redAccent
                                : (widget.isDark
                                ? Colors.white10
                                : Colors.grey[200]),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isListening
                                ? Icons.mic
                                : Icons.mic_none_rounded,
                            color: widget.isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              if (note != null)
                TextButton(
                  onPressed: () {
                    setState(() => notes.removeAt(index!));
                    _saveNotes();
                    Navigator.pop(context);
                  },
                  child: const Text("Delete",
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                ),
                onPressed: () {
                  if (contentController.text.isEmpty) return;

                  final topic = titleController.text.isNotEmpty
                      ? titleController.text
                      : contentController.text.split(" ").take(3).join(" ");

                  final newNote = {
                    "title": titleController.text,
                    "content": contentController.text,
                    "colorIndex": selectedColorIndex,
                    "date": DateTime.now().toIso8601String(),
                    "tags": [topic.split(" ").first], // 🔥 TAGS
                  };

                  setState(() {
                    if (note == null) {
                      notes.insert(0, newNote);
                    } else {
                      notes[index!] = newNote;
                    }
                  });

                  _saveNotes();
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? bgDark : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          backgroundColor: accentPurple,
          onPressed: () => _showNoteDialog(),
          child: const Icon(Icons.edit_note_rounded, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sticky Notes",
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color:
                      widget.isDark ? Colors.white : Colors.black)),
              Text("Quick thoughts & ideas",
                  style: TextStyle(
                      fontSize: 15,
                      color: textMutedDark)),
              const SizedBox(height: 32),
              Expanded(
                child: _isLoading
                    ? Center(
                    child: CircularProgressIndicator(
                        color: accentPurple))
                    : notes.isEmpty
                    ? Center(
                    child: Text("No notes yet.",
                        style:
                        TextStyle(color: textMutedDark)))
                    : GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return GestureDetector(
                      onTap: () =>
                          _showNoteDialog(note: note, index: i),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: noteColors[
                          note['colorIndex'] ?? 0],
                          borderRadius:
                          BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            if (note['title'].isNotEmpty)
                              Text(note['title'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(note['content'],
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(
                                          alpha: 0.8))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}