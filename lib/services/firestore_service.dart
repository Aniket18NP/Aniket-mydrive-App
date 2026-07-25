import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save new user
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
  }

  /// Get user once
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  /// Listen to user changes in real time
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!);
    });
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toMap());
  }

  /// Update FCM token
Future<void> updateFcmToken(
  String uid,
  String token,
) async {
  await _firestore
      .collection('users')
      .doc(uid)
      .update({
    'fcmToken': token,
  });
}

  /// Delete user
  Future<void> deleteUser(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .delete();
  }
}