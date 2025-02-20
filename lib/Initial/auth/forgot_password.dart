import 'dart:io';

import 'package:agua_med/_services/auth_Services.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../loading.dart';
import 'otp.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  var identifier = TextEditingController();
  var platform = TextEditingController();
  var token = TextEditingController();

  AuthService authService = AuthService();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  goAuth() {
    identifier.text = identifier.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (identifier.text.isEmpty) {
      showToast(context, msg: 'ForgotPasswordScreen.pleaseEnterValidEmailOrPhoneNumber'.tr());
    } else {
      if (EmailValidator.validate(identifier.text)) {
        checkEmail();
      } else {
        checkPhone();
      }
    }
  }

  checkEmail() async {
    showLoader(context, 'ForgotPasswordScreen.justAMoment'.tr());
    firestore.collection('users').where('email', isEqualTo: identifier.text).get().then((value) async {
      pop(context);
      if (value.docs.isNotEmpty) {
        await authService.sendPasswordResetEmail(context: context, email: identifier.text);
        showToast(context, msg: 'ForgotPasswordScreen.passwordResetLinkSent'.tr(), duration: 4);
      } else {
        showToast(context, msg: 'ForgotPasswordScreen.pleaseEnterValidCredentials'.tr());
      }
    });
  }

  checkPhone() async {
    showLoader(context, 'ForgotPasswordScreen.justAMoment'.tr());
    firestore.collection('users').where('phone', isEqualTo: identifier.text).get().then((value) async {
      pop(context);
      if (value.docs.isNotEmpty) {
        await authService.sendOtpToPhone(
          context: context,
          phone: identifier.text,
          onCodeSent: (String verificationId) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(verificationId: verificationId, user: value.docs.first, platform: platform.text, token: token.text)));
          },
          onVerificationFailed: (String error) {
            showToast(context, msg: error);
          },
        );
      } else {
        showToast(context, msg: 'ForgotPasswordScreen.pleaseEnterValidCredentials'.tr());
      }
    });
  }

  void fcmToken() async {
    if (!kIsWeb && Platform.isIOS) {
      await firebaseMessaging.requestPermission(sound: true, badge: true, alert: true);
    }
    platform.text = kIsWeb ? 'Web' : Platform.operatingSystem;
    try {
      String? fcm;
      if (kIsWeb) {
        fcm = await firebaseMessaging.getToken(vapidKey: 'BLkbgJWECz8Mvdzj6IVJ_TmZJ-8A52NahfQolyaPWBaNB3hwrqB-NL0dNynGgEewUnbRNXE4ZD9_75riev4y3t0');
      } else {
        fcm = await firebaseMessaging.getToken();
      }
      token.text = fcm ?? '';
    } catch (e) {}
  }

  @override
  void initState() {
    fcmToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: AppBar(
          leading: const backButton(),
          title: Text(
            'ForgotPasswordScreen.forgotPassword'.tr(),
            style: TextStyle(color: blackColor),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    width: isMobile ? width(context) : 400,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMobile ? transparentColor : darkGreyColor,
                          width: isMobile ? 0 : 0.5,
                        )),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0.0 : p, vertical: isMobile ? 0.0 : 16),
                      child: ResponsiveRowColumn(
                        layout: ResponsiveRowColumnType.COLUMN,
                        children: [
                          ResponsiveRowColumnItem(
                              child: Column(
                            children: [
                              const SizedBox(height: 60),
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/images/security.png',
                                    width: 120,
                                    color: primaryColor,
                                  ),
                                  Text(
                                    'ForgotPasswordScreen.enterYourEmailToSendOtp'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: blackColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              TextField(
                                controller: identifier,
                                decoration: InputDecoration(
                                  hintText: 'ForgotPasswordScreen.enterYourEmailOrPhoneNumber'.tr(),
                                  prefixIcon: Icon(Icons.email, color: borderColor),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Button(
                                height: 50,
                                width: width(context),
                                text: 'ForgotPasswordScreen.submit'.tr(),
                                onPressed: () {
                                  goAuth();
                                },
                              )
                            ],
                          ))
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
