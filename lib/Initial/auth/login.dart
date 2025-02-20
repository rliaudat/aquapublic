import 'dart:io';

import 'package:agua_med/Initial/auth/forgot_password.dart';
import 'package:agua_med/Initial/auth/otp.dart';
import 'package:agua_med/Initial/auth/signup.dart';
import 'package:agua_med/Initial/splashScreen.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_services/storage.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../_services/auth_Services.dart';
import '../../loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;
  var identifier = TextEditingController();
  var pass = TextEditingController();
  var platform = TextEditingController();
  var token = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  AuthService authService = AuthService();

  goAuth() {
    unFocus(context);
    identifier.text = identifier.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (identifier.text.isEmpty || pass.text.isEmpty) {
      if (identifier.text.isEmpty) {
        showToast(
          context,
          msg: 'LoginScreen.pleaseEnterEmail'.tr(),
          duration: 2,
        );
      } else if (pass.text.isEmpty) {
        showToast(
          context,
          msg: 'LoginScreen.pleaseEnterPassword'.tr(),
          duration: 2,
        );
      }
    } else {
      if (EmailValidator.validate(identifier.text)) {
        doLoginWithEmail();
      } else {
        doLoginWithPhone();
      }
    }
  }

  doLoginWithEmail() async {
    showLoader(context, 'LoginScreen.justAMoment'.tr());
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: identifier.text,
        password: pass.text,
      );
      var id = userCredential.user?.uid;
      await firestore.collection('users').doc(id).update({'platform': platform.text, 'fcm_token': token.text});
      firestore.collection('users').doc(id).get().then((user) {
        pop(context);
        if (user.exists) {
          goNext(user);
        } else {
          showToast(context, msg: 'LoginScreen.pleaseEnterValidCredentials'.tr());
        }
      });
    } catch (e) {
      pop(context);
      showToast(context, msg: 'LoginScreen.pleaseEnterValidCredentials'.tr());
    }
  }

  doLoginWithPhone() async {
    showLoader(context, 'LoginScreen.justAMoment'.tr());
    try {
      firestore.collection('users').where('phone', isEqualTo: identifier.text).get().then((value) async {
        if (value.docs.isNotEmpty) {
          await authService.sendOtpToPhone(
            context: context,
            phone: identifier.text,
            onCodeSent: (String verificationId) {
              pop(context);
              showToast(context, msg: '${'LoginScreen.otpSentTo'.tr()} ${identifier.text}');
              Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(verificationId: verificationId, user: value.docs.first, platform: platform.text, token: token.text)));
            },
            onVerificationFailed: (String error) {
              pop(context);
              showToast(context, msg: error);
            },
          );
        } else {
          pop(context);
          showToast(context, msg: 'LoginScreen.pleaseEnterValidCredentials'.tr());
        }
      });
    } catch (e) {
      pop(context);
      showToast(context, msg: 'LoginScreen.pleaseEnterValidCredentials'.tr());
    }
  }

  goNext(user) async {
    String userStatus = user['status'];
    if (userStatus == 'pending') {
      showToast(context, msg: 'LoginScreen.pleaseWaitForAdminApproval'.tr());
      return;
    }
    userSD = user.data();
    userSD['id'] = user.id;
    await Storage.setLogin(userSD);
    if (userSD['role'] == 'Manager') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManagerHomeScreen()), (route) => false);
    } else if (userSD['role'] == 'Inspector') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const InspectorHomeScreen()), (route) => false);
    } else if (userSD['role'] == 'HouseOwner') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else if (userSD['role'] == 'Admin') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()), (route) => false);
    }
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
        appBar: AppBar(toolbarHeight: 0),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isMobile ? 150 : 50),
              Center(
                child: Container(
                  width: isMobile ? width(context) : 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMobile ? transparentColor : darkGreyColor,
                      width: isMobile ? 0 : 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 0.0 : p, vertical: isMobile ? 0.0 : 16),
                    child: ResponsiveRowColumn(
                      layout: ResponsiveRowColumnType.COLUMN,
                      children: [
                        ResponsiveRowColumnItem(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SplashScreen())),
                                child: Column(
                                  children: [
                                    Image.asset('assets/images/icon.png', height: 100),
                                    const SizedBox(height: 15),
                                    Center(
                                      child: Text(
                                        'AguaMED',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            Text(
                              'LoginScreen.emailOrPhone'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            EPhoneField(
                              menuType: PickerMenuType.bottomSheet,
                              searchInputDecoration: InputDecoration(hintText: 'LoginScreen.search'.tr()),
                              initialCountry: Country.argentina,
                              pickerHeight: CountryPickerHeigth.h50,
                              onChanged: (p0) {
                                identifier.text = p0;
                              },
                              decoration: InputDecoration(
                                hintText: 'LoginScreen.enterEmailOrPhone'.tr(),
                                prefixIcon: Icon(Icons.email_outlined, color: borderColor),
                              ),
                            ),
                            SizedBox(height: p),
                            Text(
                              'LoginScreen.password'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: pass,
                              obscureText: !isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'LoginScreen.password'.tr(),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: borderColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: borderColor,
                                  ),
                                  onPressed: () {
                                    isPasswordVisible = !isPasswordVisible;
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                                  child: Text(
                                    'LoginScreen.forgotPassword'.tr(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Button(
                              height: 50,
                              text: 'LoginScreen.login'.tr(),
                              onPressed: () => goAuth(),
                            ),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LoginScreen.didntHaveAccount'.tr(),
                                  style: TextStyle(color: borderColor),
                                ),
                                SizedBox(
                                  width: isMobile ? width(context) * 0.01 : width(context) * 0.005,
                                ),
                                Center(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'LoginScreen.createAccount'.tr(),
                                          style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: isMobile ? 30 : 0),
                          ],
                        ))
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
