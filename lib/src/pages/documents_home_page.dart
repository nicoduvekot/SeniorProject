import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/document_service.dart';
import '../widgets/create_document_dialog.dart';
import 'document_editor_page.dart';

class DocumentsHomePage extends StatelessWidget {
  const DocumentsHomePage({super.key});
  
  @override 
  Widget build(BuildContext context) {
    final service = DocumentService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Documents"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log out",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => CreateDocumentDialog(
                  onCreate: service.createDocument,
                  onCheckName: service.nameExists,
              ),
            );
          },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
          stream: service.userDocumentsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!;
            if (docs.isEmpty) {
              return const Center(child: Text("No Documents yet"));
            }

            return ListView(
              children: docs.map((d) {
                return ListTile(
                  title: Text(d['name']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentEditorPage(docRef: d.reference),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
      ),
    );
  }
}