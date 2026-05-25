import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow_showcase/src/widgets/status_indicators.dart';
import '../models/document_status.dart';
import '../services/document_service.dart';
import '../widgets/create_document_dialog.dart';
import 'document_editor_page.dart';
import '../widgets/app_alert.dart';

// Used for assigning an object for search functionality
class MyObject {
  final String name;
  MyObject(this.name);
}

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

        // The addition for the search bar functionality
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: controller,
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onTap: () { controller.openView(); },
                  onChanged: (_) { controller.openView(); },
                  leading: const Icon(Icons.search),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: service.userDocumentsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final docs = snapshot.data!;
                      final query = controller.text.toLowerCase();

                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final queryLower = query.toLowerCase();

                        final fields = [
                          data['name'],
                          data['notes'],
                          data['track'],
                          data['car'],
                          data['weather'],
                          data['driver'],
                          data['suspension'],
                          data['aero'],
                        ];

                        return fields.any((value) =>
                            (value ?? '').toString().toLowerCase().contains(queryLower));
                      }).toList();

                      return Column(
                        children: filtered.map((doc) {
                          return ListTile(
                            title: Text(doc['name']),
                            onTap: () {
                              controller.closeView(doc['name']); // fills the search bar

                              // This allows for selecting the doc to see the editor
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentEditorPage(docRef: doc.reference),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  )
                ];
              },
            ),
          ),
        ),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Delete document",
                    onPressed: () async {
                      final shouldDelete = await AppAlert.showYesNoAlert(
                        context,
                        "Deletion CANNOT be undone!",
                        title: "Delete '${d['name']}'?",
                        yesText: "Delete",
                        noText: "Cancel",
                        titleColor: Colors.red,
                      );

                      if (shouldDelete) {
                        await d.reference.delete();
                      }
                    },
                  ),
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