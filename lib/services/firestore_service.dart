import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserDetails(Map<String, dynamic> userData) async {
    String uid = _auth.currentUser!.uid; // Get logged-in user's UID
    await _db.collection('users').doc(uid).set(userData);
  }

  Future<bool> isProfileComplete() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }
}
