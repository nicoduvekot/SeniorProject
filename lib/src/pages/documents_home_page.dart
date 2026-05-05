import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow_showcase/src/widgets/status_indicators.dart';
import '../models/document_status.dart';
import '../services/document_service.dart';
import '../widgets/create_document_dialog.dart';
import 'document_editor_page.dart';
import '../widgets/app_alert.dart';

class DocumentsHomePage extends StatelessWidget {
  const DocumentsHomePage({super.key});

  DocumentStatus getStatusForDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    if (doc.metadata.hasPendingWrites) {
      return DocumentStatus.syncing;
    }

    //Data that must be there for a complete document
    final hasName = data['name'] != null && data['name'].toString().isNotEmpty;
    final hasContent = data['track'] != null && data['track'].toString().isNotEmpty;

    final isComplete = hasName && hasContent;

    return isComplete
        ? DocumentStatus.complete
        : DocumentStatus.incomplete;
  }
  
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
              final shouldLogout = await AppAlert.showYesNoAlert(
                  context,
                  "Continue with log out?",
                  yesText: "Yes",
                  noText: "No",
              );
              if (shouldLogout) {
                await FirebaseAuth.instance.signOut();
              }
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
                  leading: StatusIndicators(status: getStatusForDoc(d)),
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