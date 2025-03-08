import 'dart:convert';

import 'package:agua_med/Initial/auth/verificaion_screen.dart';
import 'package:agua_med/env/env.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../loading.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  var phoneNumberController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> sendSmsOtp(String phoneNumber) async {
    String username = Env.accountSid;
    String password = Env.authToken;
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    try {
      var phoneExists = await firestore
          .collection('users')
          .where("phone", isEqualTo: phoneNumber)
          .get();
      if (phoneExists.docs.isNotEmpty) {
       if( phoneExists.docs.first.data()['encryptedPassword']=="active"){
        var headers = {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': basicAuth
        };
        var data = {'To': phoneNumber, 'Channel': 'sms'};
        var dio = Dio();
        var response = await dio.request(
          'https://verify.twilio.com/v2/Services/${Env.sidKey}/Verifications',
          options: Options(
            method: 'POST',
            headers: headers,
          ),
          data: data,
        );
        print(
            "https://verify.twilio.com/v2/Services/${Env.sidKey}/Verifications");
        print(response);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationCodeScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
       }
       else{
          showToast(context, msg: 'OtpScreen.adminApprovalMessage'.tr());
       }
        

        // Assuming a successful response, return true
        // return true;
      } else {
        showToast(context, msg: 'AuthService.thisPhoneNumberDoNotExist'.tr());
      }
    } catch (error) {
      // Print out error for debugging purposes
      print("Error occurred while sending OTP sms: ${error}");
      // Return false to indicate failure
    }
  }

  @override
  void initState() {
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
            "OTP",
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
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 0.0 : p,
                          vertical: isMobile ? 0.0 : 16),
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
                                    "Enter your phone number to get otp",
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
                                controller: phoneNumberController,
                                decoration: InputDecoration(
                                  hintText: "Phone Number",
                                  prefixIcon:
                                      Icon(Icons.phone, color: borderColor),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Button(
                                height: 50,
                                width: width(context),
                                text: 'ForgotPasswordScreen.submit'.tr(),
                                onPressed: () {
                                  sendSmsOtp(phoneNumberController.text);
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
