import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_services/auth_Services.dart';
import 'package:agua_med/_services/storage.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:otp_text_field/style.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../loading.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final dynamic user;
  final String platform;
  final String token;
  const OtpScreen({super.key, required this.verificationId, required this.user, required this.platform, required this.token});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  AuthService authService = AuthService();
  String otp = "";

  handleOtpVerification() async {
    if (otp.isEmpty || otp.length < 6) {
      showToast(context, msg: "OtpScreen.enterValidOtp".tr());
      return;
    }

    authService.verifyOtp(
      verificationId: widget.verificationId,
      otp: otp,
      onVerified: (userCredential) async {
        if (mounted) showToast(context, msg: "OtpScreen.otpVerifiedSuccess".tr());
        var id = userCredential.user?.uid;
        await FirebaseFirestore.instance.collection('users').doc(id).update({'platform': widget.platform, 'fcm_token': widget.token});
        goNext(widget.user);
      },
      onVerificationFailed: (error) {
        if (mounted) showToast(context, msg: error);
      },
    );
  }

  goNext(user) async {
    String userStatus = user['status'];
    if (userStatus == 'pending') {
      showToast(context, msg: 'OtpScreen.adminApprovalMessage'.tr());
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
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

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: AppBar(
          leading: const backButton(),
          title: Text('OtpScreen.otpScreenTitle'.tr(), style: TextStyle(color: blackColor)),
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
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0.0 : p,
                        vertical: isMobile ? 0.0 : 16,
                      ),
                      child: ResponsiveRowColumn(
                        layout: ResponsiveRowColumnType.COLUMN,
                        children: [
                          ResponsiveRowColumnItem(
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    'OtpScreen.otpSentMessage'.tr(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 60),
                                OTPTextField(
                                  length: 6,
                                  width: width(context),
                                  fieldWidth: 48,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                  textFieldAlignment: MainAxisAlignment.spaceAround,
                                  fieldStyle: FieldStyle.box,
                                  otpFieldStyle: OtpFieldStyle(
                                    borderColor: borderColor,
                                    enabledBorderColor: borderColor,
                                  ),
                                  onChanged: (value) {
                                    if (mounted) setState(() {});
                                    otp = value;
                                  },
                                  onCompleted: (value) {
                                    if (mounted) setState(() {});
                                    otp = value;
                                    handleOtpVerification();
                                  },
                                ),
                                const SizedBox(height: 60),
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'OtpScreen.waitMessage'.tr(),
                                      style: TextStyle(color: borderColor, fontSize: 11),
                                      children: [
                                        TextSpan(
                                          text: 'OtpScreen.sendAgain'.tr(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 363 : 150),
                                Button(
                                  height: 50,
                                  width: width(context),
                                  text: 'OtpScreen.submitButton'.tr(),
                                  onPressed: handleOtpVerification,
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
        ),
      ),
    );
  }
}
