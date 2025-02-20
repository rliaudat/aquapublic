import 'dart:io';
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

  //For signup=======================================
  Future<void> signup({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String isoCode,
    required String dialCode,
    required dynamic town,
    required dynamic house,
    required String password,
    required String platform,
    required String token,
    File? profileImage,
  }) async {
    try {
      showLoader(context, 'Just a moment...');

      // Encrypt the password
      final encryptionResult = encryptPass(text: password, key: 'SECRET_KEY');
      var emailExists = await firestore.collection('users').where("email", isEqualTo: email).get();
      if (emailExists.docs.isNotEmpty) {
        throw Exception('AuthService.thisEmailAddressIsAlreadyRegistered'.tr());
      }
      var phoneExists = await firestore.collection('users').where("phone", isEqualTo: phone).get();
      if (phoneExists.docs.isNotEmpty) {
        throw Exception('AuthService.thisPhoneNumberIsAlreadyRegistered'.tr());
      }

      // Create the user with Firebase Authentication
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Upload profile image if provided
      String? profileImageUrl;
      if (profileImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${userCredential.user?.uid}.jpg');

        await storageRef.putFile(profileImage);
        profileImageUrl = await storageRef.getDownloadURL();
      }

      // Save user data to Firestore
      final id = userCredential.user?.uid;
      if (id == null) {
        throw Exception('AuthService.somethingWentWrong'.tr());
      }

      final obj = {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'isoCode': isoCode,
        'dialCode': dialCode,
        'town': town,
        'house': house,
        'profileImageUrl': profileImageUrl,
        'role': 'pending',
        'status': 'pending',
        'encryptedPassword': encryptionResult.encryptedData,
        'iv': encryptionResult.iv,
        'isDeleted': false,
        'platform': platform,
        'fcm_token': token,
      };

      await firestore.collection('users').doc(id).set(obj);
      showToast(context, msg: 'AuthService.verificationEmailSent'.tr(), duration: 3);
    } on FirebaseAuthException catch (e) {
      pop(context);
      showToast(context, msg: 'AuthService.failedToSignUp'.tr() + '${e.message}', duration: 3);
      print('FirebaseAuthException: ${e.message}');
      throw Exception('AuthService.failedToSignUp'.tr() + '${e.message}');
    } catch (e) {
      pop(context);
      showToast(context, msg: 'AuthService.anErrorOccurred'.tr() + '$e', duration: 3);
    }
  }

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
          onVerificationFailed(e.message ?? "AuthService.verificationFailed".tr());
        },
        codeSent: (String verificationId, int? resendToken) {
          print("AuthService.otpSentTo".tr() + '$phone, Verification ID: $verificationId');
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
      UserCredential userCredential = await auth.signInWithCredential(credential);
      onVerified(userCredential);
      print("AuthService.userVerifiedAndSignedIn".tr());
    } catch (e) {
      print("OTP verification failed: $e");
      onVerificationFailed(e.toString());
    }
  }

  //Rest Password by email===========================================
  sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      showToast(context, msg: "AuthService.passwordResetLinkSent".tr() + '$email');
    } on FirebaseAuthException catch (e) {
      print("AuthService.failedToSendPasswordResetEmail".tr() + '${e.message}');
      showToast(context, msg: "AuthService.failedToSendPasswordResetEmail".tr() + '${e.message}');
    } catch (e) {
      print("AuthService.error".tr() + '$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AuthService.error".tr() + '$e')),
      );
    }
  }

  Future createUser({required String firstName, required String lastName, required String email, required String phone, required var town, var house, required String password, required String role, File? profileImage, isoCode, dialCode}) async {
    try {
      var emailExists = await firestore.collection('users').where("email", isEqualTo: email).get();
      if (emailExists.docs.isNotEmpty) {
        return 'AuthService.thisEmailAddressIsAlreadyRegistered'.tr();
      }
      var phoneExists = await firestore.collection('users').where("phone", isEqualTo: phone).get();
      if (phoneExists.docs.isNotEmpty) {
        return 'AuthService.thisPhoneNumberIsAlreadyRegistered'.tr();
      }

      final encryptionResult = encryptPass(text: password, key: 'SECRET_KEY');
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      var id = userCredential.user?.uid;

      String? profileImageUrl;
      if (profileImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('$id.jpg');
        await storageRef.putFile(profileImage);
        profileImageUrl = await storageRef.getDownloadURL();
      }

      // Prepare user data
      var obj = {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'isoCode': isoCode,
        'dialCode': dialCode,
        'town': town,
        'house': house,
        'profileImageUrl': profileImageUrl,
        'role': role,
        'status': 'active',
        'encryptedPassword': encryptionResult.encryptedData,
        'iv': encryptionResult.iv,
        'isDeleted': false,
      };
      await firestore.collection('users').doc(id).set(obj);
      return 'AuthService.success'.tr();
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future updateUser(obj) async {
    try {
      String? profileImageUrl;

      if (obj['profileImage'] != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${obj['id']}.jpg');
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
