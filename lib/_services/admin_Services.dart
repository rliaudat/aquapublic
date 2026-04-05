import 'package:agua_med/_helpers/global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';

import '../loading.dart';

class AdminService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //To Show verification of Users who signed Up========================

  // Stream pendingUsers() {
  //   return firestore
  //       .collection('users')
  //       .where('status', isEqualTo: 'pending')
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs.where((doc) {
  //       final isDeleted = doc.data()['isDeleted'];
  //       return isDeleted == null || isDeleted == false;
  //     }).map((doc) {
  //       var obj = doc.data();
  //       obj['id'] = doc.id;
  //       return obj;
  //     }).toList();
  //   });
  // }

  //Registered HouseOwners================================
  Stream<dynamic> fetchAllUsers(role) {
    if (userSD['role'] == 'Admin') {
      return firestore
          .collection('user')
          .where('role', isEqualTo: role)
          .where('isDeleted', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          var obj = doc.data();
          obj['id'] = doc.id;
          return obj;
        }).toList();
      });
    } else {
      var town = userSD['town'];
      if (town != null) {
        var townId = town['id'];
        if (role == 'HouseOwner') {
          return firestore
              .collection('user')
              .where('role', isEqualTo: role)
              .where('town.id', isEqualTo: townId)
              .where('isDeleted', isEqualTo: false)
              .snapshots()
              .map((snapshot) {
            return snapshot.docs.map((doc) {
              var obj = doc.data();
              obj['id'] = doc.id;
              return obj;
            }).toList();
          });
        } else {
          return firestore
              .collection('user')
              .where('role', isEqualTo: role)
              .where('isDeleted', isEqualTo: false)
              .snapshots()
              .map((snapshot) {
            return snapshot.docs.where((doc) {
              var towns = doc.data()['town'];
              if (towns != null) {
                for (var town in towns) {
                  if (town['id'] == townId) {
                    return true;
                  }
                }
              }
              return false;
            }).map((doc) {
              var obj = doc.data();
              obj['id'] = doc.id;
              return obj;
            }).toList();
          });
        }
      } else {
        return const Stream.empty();
      }
    }
  }

  //Registered Inspector==============================
  Stream registeredInspectors() {
    return firestore
        .collection('user')
        .where('role', isEqualTo: 'Inspector')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final isDeleted = doc.data()['isDeleted'];
        return isDeleted == null || isDeleted == false;
      }).map((doc) {
        return {
          'id': doc.id,
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'email': doc['email'],
          'phone': doc['phone'],
          'town': doc['town'],
          'role': doc['role'],
          'status': doc['status'],
          'profileImageUrl': doc['profileImageUrl']
        };
      }).toList();
    });
  }

  //Registered Manager==============================
  Stream registeredManagers() {
    return firestore
        .collection('user')
        .where('role', isEqualTo: 'Manager')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final isDeleted = doc.data()['isDeleted'];
        return isDeleted == null || isDeleted == false;
      }).map((doc) {
        return {
          'id': doc.id,
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'email': doc['email'],
          'phone': doc['phone'],
          'town': doc['town'],
          'role': doc['role'],
          'status': doc['status'],
          'profileImageUrl': doc['profileImageUrl']
        };
      }).toList();
    });
  }

  //block user========================================
  blockUser(String userId) async {
    await firestore
        .collection('user')
        .doc(userId)
        .update({'status': 'blocked'});
  }

  //UnblockUser========================================
  unblockUser(String userId) async {
    await firestore.collection('user').doc(userId).update({'status': 'active'});
  }

  //Delete user======================================
  Future<void> deleteUser(String userId) async {
    DocumentReference userDoc = firestore.collection('user').doc(userId);
    await userDoc.set({'isDelete': true}, SetOptions(merge: true));
  }

  //updateUserDetails==============================================

  updateUserDetails({
    required BuildContext context,
    required String userId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      showLoader(context, 'AdminService.updatingUserDetails'.tr());

      DocumentReference userRef = firestore.collection('user').doc(userId);

      await userRef.update(updatedData);

      showToast(context,
          msg: 'AdminService.userDetailsUpdatedSuccessfully'.tr(), duration: 2);
    } on FirebaseException catch (e) {
      showToast(context,
          msg: '${'AdminService.error'.tr()}: ${e.message}', duration: 2);
    } catch (e) {
      showToast(context,
          msg: 'AdminService.somethingWentWrongTryAgain'.tr(), duration: 2);
    }
  }
}
