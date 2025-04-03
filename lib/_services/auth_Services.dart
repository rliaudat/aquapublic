import 'dart:io';
import 'package:agua_med/_services/user_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../_helpers/encrypption.dart';
import '../loading.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  sendOtpToPhone({
    required BuildContext context,
    required String phone,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
  }) async {
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
          print("AuthService.phoneNumberAutomaticallyVerified".tr());
        },
        verificationFailed: (FirebaseAuthException e) {
          print("AuthService.verificationFailed".tr() + '${e.message}');
          onVerificationFailed(
              e.message ?? "AuthService.verificationFailed".tr());
        },
        codeSent: (String verificationId, int? resendToken) {
          print("AuthService.otpSentTo".tr() +
              '$phone, Verification ID: $verificationId');
          onCodeSent(verificationId);
          showToast(context, msg: 'AuthService.otpSentTo'.tr() + '$phone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("AuthService.autoRetrievalTimeout".tr() + '$verificationId');
        },
      );
    } catch (e) {
      showToast(context, msg: 'Failed to send OTP');
    }
  }

  //Verify OTP===========================================
  verifyOtp({
    required String verificationId,
    required String otp,
    required Function(UserCredential) onVerified,
    required Function(String) onVerificationFailed,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential userCredential =
          await auth.signInWithCredential(credential);
      onVerified(userCredential);
      print("AuthService.userVerifiedAndSignedIn".tr());
    } catch (e) {
      print("OTP verification failed: $e");
      onVerificationFailed(e.toString());
    }
  }

  Future createUser({
    required AppUser user,
    required String password,
    File? image,
  }) async {
    try {
      var fetchEmail = await UserServices.fetchByEmail(user.email);
      if (fetchEmail != null) {
        return 'AuthService.thisEmailAddressIsAlreadyRegistered'.tr();
      }
      var fetchPhoneNumber = await UserServices.fetchByPhone(user.phoneNumber);
      if (fetchPhoneNumber != null) {
        return 'AuthService.thisPhoneNumberIsAlreadyRegistered'.tr();
      }

      final encryptionResult = encryptPass(text: password, key: 'SECRET_KEY');
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      String? profileImageURL;
      if (image != null) {
        profileImageURL = await UserServices.storeProfileImage(
            userCredential.user?.uid ?? 'Not Assigned', image);
      }

      await UserServices.register(
        user.copyWith(
          uid: userCredential.user?.uid ?? 'Not Assigned',
          encryptedPassword: encryptionResult.encryptedData,
          iv: encryptionResult.iv,
          profileImageURL: profileImageURL,
        ),
      );
      await auth.signOut();
      return 'AuthService.success'.tr();
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future updateUser(obj) async {
    try {
      String? profileImageUrl;

      if (obj['profileImage'] != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${obj['id']}.jpg');
        await storageRef.putFile(obj['profileImage']);
        profileImageUrl = await storageRef.getDownloadURL();
      }

      if (profileImageUrl != null) {
        obj['profileImageUrl'] = profileImageUrl;
      }
      await firestore.collection('users').doc(obj['id']).update(obj);
      return 'AuthService.success'.tr();
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
