import 'dart:convert';
import 'dart:io';

import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_helpers/encrypption.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_services/storage.dart';
import 'package:agua_med/env/env.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:responsive_framework/responsive_framework.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationCodeScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  FirebaseAuth auth = FirebaseAuth.instance;
  var platform = TextEditingController();
  var token = TextEditingController();

  final TextEditingController pinController = TextEditingController();

  void fcmToken() async {
    if (!kIsWeb && Platform.isIOS) {
      await firebaseMessaging.requestPermission(
          sound: true, badge: true, alert: true);
    }
    platform.text = kIsWeb ? 'Web' : Platform.operatingSystem;
    try {
      String? fcm;
      if (kIsWeb) {
        fcm = await firebaseMessaging.getToken(
            vapidKey:
                'BLkbgJWECz8Mvdzj6IVJ_TmZJ-8A52NahfQolyaPWBaNB3hwrqB-NL0dNynGgEewUnbRNXE4ZD9_75riev4y3t0');
      } else {
        fcm = await firebaseMessaging.getToken();
      }
      token.text = fcm ?? '';
      // ignore: empty_catches
    } catch (e) {}
  }

  goNext(user) async {
    String userStatus = user['status'];
    if (userStatus == 'pending') {
      showToast(context, msg: 'OtpScreen.adminApprovalMessage'.tr());
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false);
      return;
    }
    userSD = user;
    // userSD['id'] = user.id;

    await Storage.setLogin(userSD);
    if (userSD['role'] == 'Manager') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ManagerHomeScreen()),
          (route) => false);
    } else if (userSD['role'] == 'Inspector') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const InspectorHomeScreen()),
          (route) => false);
    } else if (userSD['role'] == 'HouseOwner') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false);
    } else if (userSD['role'] == 'Admin') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          (route) => false);
    }
  }

  Future<void> verifyOtp(String code, String phoneNumber) async {
    try {
      String username = Env.accountSid;
      String password = Env.authToken;
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': basicAuth
      };
      var data = {'To': phoneNumber, 'Code': code};
      var dio = Dio();
      var response = await dio.request(
        'https://verify.twilio.com/v2/Services/${Env.sidKey}/VerificationCheck',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      if (response.data['status'] == 'approved') {
        fcmToken();
        var userData = await firestore
            .collection('users')
            .where("phone", isEqualTo: phoneNumber)
            .get();
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: userData.docs.first.data()['email'],
          password: decryptPass(
              text: userData.docs.first.data()['encryptedPassword'],
              iv: userData.docs.first.data()['iv'],
              key: 'SECRET_KEY'),
        );
        if (mounted) {
          showToast(context, msg: "OtpScreen.otpVerifiedSuccess".tr());
        }
        var id = userCredential.user?.uid;
        await FirebaseFirestore.instance.collection('users').doc(id).update({
          'platform': platform.text,
          'fcm_token': token.text,
        });
        goNext(userData.docs.first.data());
      } else {
        if (mounted) {
          showToast(context, msg: "OtpScreen.enterValidOtp".tr());
        }
      }

      // Assuming a successful response, return true
    } catch (error) {
      // Print out error for debugging purposes
      if (kDebugMode) {
        print("Error occurred while Verifying OTP email: $error");
      }
      // Return false to indicate failure
      // return IsVerified.errorInVerification;
    }
  }

  @override
  Widget build(BuildContext context) {
     bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
    TextTheme textTheme = Theme.of(context).textTheme;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          leading: const backButton(),
         
        ),
        body: Padding(
           padding: EdgeInsets.symmetric(horizontal: p),
          child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                     width: isMobile ? width(context) : 400,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMobile ? transparentColor : darkGreyColor,
                                  width: isMobile ? 0 : 0.5,
                                )),
                      // height: 670,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0.0 : p, vertical: isMobile ? 0.0 : 16),
                      child: ResponsiveRowColumn(
                        layout: ResponsiveRowColumnType.COLUMN,
                        children: [
                          ResponsiveRowColumnItem(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Padding(
                              //   padding: const EdgeInsets.only(top: 10),
                              //   child: Row(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: [
                              //       InkWell(
                              //         onTap: () {
                              //           Navigator.of(context).pop();
                              //         },
                              //         child: const Icon(Icons.arrow_back),
                              //       )
                              //     ],
                              //   ),
                              // ),
                              SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                height: 600,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(left: 11),
                                            child: SizedBox(
                                              width: 285,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Verification Code",
                                                    style: TextStyle(fontSize: 24),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    "Enter your email, we will send a verification code to your email",
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Form(
                                          key: _formKey,
                                          child: Pinput(
                                            controller: pinController,
                                            defaultPinTheme: PinTheme(
                                              width: 56,
                                              height: 56,
                                              textStyle: TextStyle(
                                                  fontSize: 24,
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600),
                                              decoration: BoxDecoration(
                                                border:
                                                    Border.all(color: colorScheme.primary),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return "Pin must ne entered";
                                              } else if (value.length < 4) {
                                                return "Enter full";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 34,
                                        ),
                                        Text(
                                          "Resend Code",
                                          style: TextStyle(fontSize: 14, color: primaryColor),
                                        ),
                                      ],
                                    ),
                                    Button(
                                      width: 250,
                                      height: 40,
                                      text: "Verify",
                                      onPressed: () async {
                                        await verifyOtp(
                                            pinController.text, widget.phoneNumber);
                                        print('Completed');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
