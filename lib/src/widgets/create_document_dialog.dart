import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/document_editor_page.dart';

class CreateDocumentDialog extends StatefulWidget {
  final Future<DocumentReference> Function(String name) onCreate;
  final Future<bool> Function(String name) onCheckName;

  const CreateDocumentDialog({
    super.key,
    required this.onCreate,
    required this.onCheckName,
  });

  @override
  State<CreateDocumentDialog> createState() => _CreateDocumentDialogState();
}

class _CreateDocumentDialogState extends State<CreateDocumentDialog> {
  final controller = TextEditingController();
  bool creating = false;

  @override
  Widget build(BuildContext context)
  {
    return AlertDialog(
      title: const Text("Create Document"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: "Document Name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: creating ? null : () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;

            setState(() => creating = true);

            final exists = await widget.onCheckName(name);
            if (exists) {
              setState(() => creating = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("A document with that name already exists"),
                ),
              );
              return;
            }

            final docRef = await widget.onCreate(name);

            if (!mounted) return;
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentEditorPage(docRef: docRef),
              ),
            );
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}