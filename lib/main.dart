import 'package:flutter/material.dart';
import 'note_api.dart';

void main() {
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notepad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NotepadScreen(),
    );
  }
}

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  List<Note> notes = [];
  bool isLoading = false;
  String? editingId;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => isLoading = true);
    try {
      final fetchedNotes = await NoteApiService.getNotes();
      setState(() {
        notes = fetchedNotes;
      });
    } catch (e) {
      _showError("Failed to load notes: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showError("Please fill in both title and content!");
      return;
    }

    setState(() => isLoading = true);
    try {
      final newNote = Note(id: '', title: title, content: content);

      if (editingId != null) {
        await NoteApiService.updateNote(editingId!, newNote);
      } else {
        await NoteApiService.createNote(newNote);
      }

      _clearForm();
      await _fetchNotes();
    } catch (e) {
      _showError("Failed to save note: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      await NoteApiService.deleteNote(id);
      await _fetchNotes(); // Refresh the list
    } catch (e) {
      _showError("Failed to delete note: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _startEdit(Note note) {
    setState(() {
      editingId = note.id;
      titleController.text = note.title;
      contentController.text = note.content;
    });
  }

  void _clearForm() {
    setState(() {
      editingId = null;
      titleController.clear();
      contentController.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Notepad'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Note Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note Content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (editingId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: OutlinedButton(
                              onPressed: _clearForm,
                              child: const Text('Cancel'),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: isLoading ? null : _saveNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: editingId != null ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(editingId != null ? 'Update Note' : 'Save Note'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: isLoading && notes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notes.isEmpty
                  ? const Center(child: Text('No notes yet. Create one above!'))
                  : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _startEdit(note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNote(note.id),
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
    );
  }
}