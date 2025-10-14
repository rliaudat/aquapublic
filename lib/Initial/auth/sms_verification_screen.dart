import 'dart:convert';

import 'package:agua_med/Initial/auth/verificaion_screen.dart';
import 'package:agua_med/env/env.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
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
  dynamic isoCode;
  dynamic dialCode;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  PhoneNumber phoneNumber = PhoneNumber(
      isoCode: Country.argentina.alpha2,
      dialCode: '+${Country.argentina.dialCode}',
      phoneNumber: '');

  Future<void> sendSmsOtp(String phoneNumber) async {
    String username = Env.accountSid;
    String password = Env.authToken;
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    try {
      isLoading = true;
      setState(() {});
      var phoneExists = await firestore
          .collection('user')
          .where("phoneNumber", isEqualTo: phoneNumber)
          .get();
      if (phoneExists.docs.isNotEmpty) {
        if (phoneExists.docs.first.data()['status'] == "active") {
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
          isLoading = false;
          setState(() {});
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationCodeScreen(
                phoneNumber: phoneNumber,
              ),
            ),
          );
        } else {
          isLoading = false;
          setState(() {});
          showToast(context, msg: 'OtpScreen.adminApprovalMessage'.tr());
        }

        // Assuming a successful response, return true
        // return true;
      } else {
        isLoading = false;
        setState(() {});
        showToast(context, msg: 'AuthService.thisPhoneNumberDoNotExist'.tr());
      }
    } catch (error) {
      isLoading = false;
      setState(() {});
      showToast(context, msg: 'AuthService.somethingWentWrong'.tr());
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
                              Container(
                                padding: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(p),
                                ),
                                child: InternationalPhoneNumberInput(
                                  initialValue: phoneNumber,
                                  autoValidateMode: AutovalidateMode.disabled,
                                  onInputChanged: (PhoneNumber number) {
                                    phoneNumberController.text =
                                        number.phoneNumber!;
                                    isoCode = number.isoCode!;
                                    dialCode = number.dialCode!;
                                  },
                                  searchBoxDecoration: InputDecoration(
                                    hintText: 'SignUpScreen.search'.tr(),
                                  ),
                                  selectorConfig: const SelectorConfig(
                                    selectorType:
                                        PhoneInputSelectorType.BOTTOM_SHEET,
                                    leadingPadding: 0,
                                    trailingSpace: false,
                                    setSelectorButtonAsPrefixIcon: false,
                                    useBottomSheetSafeArea: true,
                                  ),
                                  inputDecoration: InputDecoration(
                                    hintText: 'SignUpScreen.phoneNumber'.tr(),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                        left: 0, top: 15, bottom: 15, right: 0),
                                  ),
                                ),
                              ),
                              // TextField(
                              //   controller: phoneNumberController,
                              //   decoration: InputDecoration(
                              //     hintText: "Phone Number",
                              //     prefixIcon:
                              //         Icon(Icons.phone, color: borderColor),
                              //   ),
                              // ),
                              const SizedBox(height: 40),
                              isLoading == true
                                  ? const CircularProgressIndicator()
                                  : Button(
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
