import 'dart:io';

import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../_services/auth_Services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  List towns = [];
  List houses = [];
  dynamic selectedTown;
  dynamic selectedHouse;

  var firstName = TextEditingController();
  var lastName = TextEditingController();
  var email = TextEditingController();
  PhoneNumber phoneNumber = PhoneNumber(isoCode: Country.argentina.alpha2, dialCode: '+${Country.argentina.dialCode}', phoneNumber: '');
  var phone = TextEditingController();
  dynamic isoCode;
  dynamic dialCode;
  var password = TextEditingController();
  var confirmPassword = TextEditingController();

  AuthService authService = AuthService();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  File? profileImage;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  var platform = TextEditingController();
  var token = TextEditingController();

  // Functions
  @override
  void initState() {
    fcmToken();
    fetchTowns();
    super.initState();
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

  fetchTowns() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('towns').orderBy('createdAt').get();
    towns = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {'id': doc.id, 'name': data['name']};
    }).toList();
    if (mounted) setState(() {});
  }

  fetchHouses() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('towns').doc(selectedTown['id']).collection('houses').get();
    houses = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {'id': doc.id, 'name': data['name']};
    }).toList();
    if (mounted) setState(() {});
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      profileImage = File(pickedFile.path);
      if (mounted) setState(() {});
    }
  }

  goAuth() {
    email.text = email.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty || email.text.isEmpty || phone.text.isEmpty || selectedTown == null || selectedHouse == null || password.text.isEmpty || confirmPassword.text.isEmpty) {
      if (firstName.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.firstNameRequired'.tr());
      } else if (lastName.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.lastNameRequired'.tr());
      } else if (email.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.emailRequired'.tr());
      } else if (phone.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.phoneNumberRequired'.tr());
      } else if (selectedTown == null) {
        showToast(context, msg: 'SignUpScreen.townRequired'.tr());
      } else if (selectedHouse == null) {
        showToast(context, msg: 'SignUpScreen.houseRequired'.tr());
      } else if (password.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.passwordRequired'.tr());
      } else if (confirmPassword.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.confirmPasswordRequired'.tr());
      }
      return;
    }

    if (password.text != confirmPassword.text) {
      showToast(context, msg: 'SignUpScreen.passwordMismatch'.tr());
      return;
    }

    doSignup();
  }

  doSignup() async {
    try {
      await authService.signup(
        context: context,
        firstName: firstName.text,
        lastName: lastName.text,
        email: email.text,
        phone: phone.text,
        isoCode: isoCode,
        dialCode: dialCode,
        town: selectedTown,
        house: selectedHouse,
        password: password.text,
        profileImage: profileImage,
        platform: platform.text,
        token: token.text,
      );

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
    } catch (e) {
      showToast(context, msg: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isMobile ? AppBar(leading: const backButton()) : null,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: profileImage != null ? Image.file(profileImage!, fit: BoxFit.cover) : Image.asset('assets/avatar.png'),
                          ),
                        ),
                        Positioned(
                          top: 70,
                          left: 70,
                          child: CircleAvatar(
                            backgroundColor: primaryColor,
                            radius: 15,
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: whiteColor,
                              size: 18,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SignUpScreen.firstName'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: firstName,
                  decoration: InputDecoration(hintText: 'SignUpScreen.yourFirstName'.tr()),
                ),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.lastName'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lastName,
                  decoration: InputDecoration(hintText: 'SignUpScreen.yourLastName'.tr()),
                ),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.email'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    hintText: 'SignUpScreen.email'.tr(),
                    prefixIcon: Icon(Icons.email, color: borderColor),
                  ),
                ),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.phoneNumber'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                      phone.text = number.phoneNumber!;
                      isoCode = number.isoCode!;
                      dialCode = number.dialCode!;
                    },
                    searchBoxDecoration: InputDecoration(
                      hintText: 'SignUpScreen.search'.tr(),
                    ),
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
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
                      contentPadding: const EdgeInsets.only(left: 0, top: 15, bottom: 15, right: 0),
                    ),
                  ),
                ),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.town'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownSearch(
                  selectedItem: selectedTown,
                  items: (filter, infiniteScrollProps) => towns,
                  itemAsString: (item) => item['name'].toString(),
                  onChanged: (value) {
                    selectedTown = value;
                    selectedHouse = null;
                    fetchHouses();
                  },
                  compareFn: (item, _) => item['id'] == _['id'],
                  popupProps: PopupProps.dialog(
                    showSearchBox: true,
                    constraints: const BoxConstraints(minHeight: 400),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'SignUpScreen.search'.tr(),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    fit: FlexFit.loose,
                    title: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        'SignUpScreen.selectTown'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: p),
                    Text(
                      'SignUpScreen.house'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch(
                      selectedItem: selectedHouse,
                      items: (filter, infiniteScrollProps) => houses,
                      itemAsString: (item) => item['name'].toString(),
                      onChanged: (value) {
                        selectedHouse = value;
                        if (mounted) setState(() {});
                      },
                      compareFn: (item, _) => item['id'] == _['id'],
                      popupProps: PopupProps.dialog(
                        showSearchBox: true,
                        constraints: const BoxConstraints(minHeight: 400),
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'SignUpScreen.search'.tr(),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        fit: FlexFit.loose,
                        title: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            'SignUpScreen.selectHouse'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.password'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  obscureText: isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'SignUpScreen.password'.tr(),
                    prefixIcon: Icon(Icons.lock, color: borderColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: borderColor,
                      ),
                      onPressed: () {
                        isPasswordVisible = !isPasswordVisible;
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(height: p),
                SizedBox(height: p),
                Text(
                  'SignUpScreen.confirmPassword'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPassword,
                  obscureText: isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'SignUpScreen.confirmPassword'.tr(),
                    prefixIcon: Icon(Icons.lock, color: borderColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: borderColor,
                      ),
                      onPressed: () {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(height: p),
                SizedBox(
                  height: p,
                ),
                Button(height: 45, text: 'SignUpScreen.signup'.tr(), onPressed: () => goAuth()),
                SizedBox(
                  height: p,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "SignUpScreen.alreadyHaveAccount".tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: borderColor,
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? width(context) * 0.01 : width(context) * 0.005,
                    ),
                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
                          child: Text(
                            'SignUpScreen.login'.tr(),
                            style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
