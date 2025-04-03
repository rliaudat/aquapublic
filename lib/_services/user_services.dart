import 'dart:io';
import 'package:agua_med/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserServices {
  static final _userCollection = FirebaseFirestore.instance.collection(
    'user',
  );

  static Future<AppUser?> fetchByEmail(String email) async {
    QuerySnapshot snapshot = await _userCollection
        .where('email', isEqualTo: email)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromDoc(snapshot.docs.first);
    } else {
      return null;
    }
  }

  static Future<AppUser?> fetchByPhone(String phoneNumber) async {
    QuerySnapshot snapshot = await _userCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromDoc(snapshot.docs.first);
    } else {
      return null;
    }
  }

  static Future<AppUser?> fetchById(String uid) async {
    DocumentSnapshot snapshot = await _userCollection.doc(uid).get();
    if (snapshot.exists) {
      return AppUser.fromDoc(snapshot);
    } else {
      return null;
    }
  }

  static Future<List> fetchByRole(String role) async {
    QuerySnapshot snapshot = await _userCollection
        .where('role', isEqualTo: role)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => AppUser.fromDoc(doc)).toList();
    } else {
      return [];
    }
  }

  static Future<void> register(AppUser user) async {
    await _userCollection.doc(user.uid).set(user.toMap());
  }

  static Future<String> update({
    required String uid,
    required Map<String, dynamic> data,
    File? image,
  }) async {
    try {
      String? profileImageURL;

      if (image != null) {
        profileImageURL = await storeProfileImage(uid, image);
      }

      if (profileImageURL != null) {
        data['profileImageURL'] = profileImageURL;
      }
      await _userCollection.doc(uid).update(data);
      return 'AuthService.success'.tr();
    } on FirebaseAuthException catch (e) {
      return '${'AuthService.error'.tr()} $e';
    }
  }

  static Future<String> storeProfileImage(String uid, File image) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  static Stream<List<AppUser>> userStream() {
    return _userCollection
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return AppUser.fromDoc(doc);
          }).toList(),
        );
  }

  static Stream<List<AppUser>> userByRoleStream(String role) {
    return _userCollection
        .where('role', isEqualTo: role)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return AppUser.fromDoc(doc);
          }).toList(),
        );
  }

  static Stream<List<AppUser>> userByStatusStream(
    String status,
    Map town,
    bool isDesktop,
  ) {
    return isDesktop
        ? _userCollection
            .where('status', isEqualTo: status)
            .where('town', isEqualTo: town)
            .where('isDelete', isEqualTo: false)
            .orderBy('createdAt')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs.map((doc) {
                return AppUser.fromDoc(doc);
              }).toList(),
            )
        : _userCollection
            .where('status', isEqualTo: status)
            .where('isDelete', isEqualTo: false)
            .orderBy('createdAt')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs.map((doc) {
                return AppUser.fromDoc(doc);
              }).toList(),
            );
  }
}
