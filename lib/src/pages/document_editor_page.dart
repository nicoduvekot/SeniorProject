import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentEditorPage extends StatefulWidget {
  final DocumentReference docRef;

  const DocumentEditorPage({super.key, required this.docRef});

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  final controller = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final snap = await widget.docRef.get();
    controller.text = snap['content'] ?? '';
    setState(() => loading = false);
  }

  Future<void> _save() async {
    await widget.docRef.update({
      'content': controller.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Document")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: "Track",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
            onPressed: _save,
            child: const Text("Save Document"),
        ),
      ),
    );
  }
}