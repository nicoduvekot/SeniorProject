import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentService {
  final _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<QueryDocumentSnapshot>> userDocumentsStream() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('documents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Future<bool> nameExists(String name) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('documents')
        .where('name', isEqualTo: name)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<DocumentReference> createDocument(String name) async {
    final ref = await _db
        .collection('users')
        .doc(uid)
        .collection('documents')
        .add({
      'name': name,
      'content': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref;
  }
}