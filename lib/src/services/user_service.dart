import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> ensureUserDocument() async {
    final user = FirebaseAuth.instance.currentUser!;
    final docRef = _db.collection('users').doc(user.uid);

    if (!(await docRef.get()).exists) {
      await docRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}