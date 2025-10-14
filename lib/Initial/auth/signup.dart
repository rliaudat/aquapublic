import 'dart:io';

import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/bloc/authentication/authentication_bloc.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/signup_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../_services/auth_services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  var firstName = TextEditingController();
  var lastName = TextEditingController();
  var email = TextEditingController();
  PhoneNumber phoneNumber = PhoneNumber(
      isoCode: Country.argentina.alpha2,
      dialCode: '+${Country.argentina.dialCode}',
      phoneNumber: '');
  var phone = TextEditingController();
  dynamic isoCode;
  dynamic dialCode;
  var password = TextEditingController();
  var confirmPassword = TextEditingController();

  AuthService authService = AuthService();

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  var platform = TextEditingController();
  var token = TextEditingController();

  // Functions
  @override
  void initState() {
    context.read<SignUpProvider>().fetchTowns();
    fcmToken();
    super.initState();
  }

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

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      context.read<SignUpProvider>().setProfileImage(File(pickedFile.path));
    }
  }

  goAuth() {
    email.text = email.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        email.text.isEmpty ||
        email.text.isEmpty ||
        phone.text.isEmpty ||
        context.read<SignUpProvider>().selectedTown == null ||
        context.read<SignUpProvider>().selectedHouse == null ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      if (firstName.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.firstNameRequired'.tr());
      } else if (lastName.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.lastNameRequired'.tr());
      } else if (email.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.emailRequired'.tr());
      } else if (phone.text.isEmpty) {
        showToast(context, msg: 'SignUpScreen.phoneNumberRequired'.tr());
      } else if (context.read<SignUpProvider>().selectedTown == null) {
        showToast(context, msg: 'SignUpScreen.townRequired'.tr());
      } else if (context.read<SignUpProvider>().selectedHouse == null) {
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
      BlocProvider.of<AuthenticationBloc>(context).add(
        RegisterByEmail(
          user: AppUser(
            uid: '',
            firstName: firstName.text,
            lastName: lastName.text,
            email: email.text,
            phoneNumber: phone.text,
            isoCode: isoCode,
            dialCode: dialCode,
            role: 'pending',
            status: 'pending',
            platform: platform.text,
            fcmToken: token.text,
            isDelete: false,
            profileImageURL: '',
            town: {
              'id': context.read<SignUpProvider>().selectedTown.id,
              'name': context.read<SignUpProvider>().selectedTown.name,
            },
            house: {
              'id': context.read<SignUpProvider>().selectedHouse.id,
              'name': context.read<SignUpProvider>().selectedHouse.name,
            },
            encryptedPassword: '',
            iv: '',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
          password: password.text,
          image: context.read<SignUpProvider>().profileImage,
        ),
      );
    } catch (e) {
      showToast(context, msg: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return GestureDetector(
      onTap: () => unFocus(context),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is EmailAuthenticationStarted) {
            showLoader(context, 'Just a moment...');
          }

          if (state is EmailUnverified) {
            if (kIsWeb) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false);
            } else {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }

            showToast(
              context,
              msg: 'AuthService.verificationEmailSent'.tr(),
              duration: 3,
            );
          }
          if (state is EmailAuthenticationFailed) {
            Navigator.pop(context);
            showToast(
              context,
              msg: state.error,
              duration: 3,
            );
          }
        },
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              context.read<SignUpProvider>().reset();
            }
          },
          child: Scaffold(
            body: Consumer<SignUpProvider>(
              builder: (context, provider, child) {
                return Padding(
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
                                    child: provider.profileImage != null
                                        ? (kIsWeb
                                            ? Image.network(
                                                provider.profileImage!.path,
                                                fit: BoxFit.cover)
                                            : Image.file(provider.profileImage!,
                                                fit: BoxFit.cover))
                                        : Image.asset('assets/avatar.png'),
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
                          decoration: InputDecoration(
                              hintText: 'SignUpScreen.yourFirstName'.tr()),
                        ),
                        SizedBox(height: p),
                        Text(
                          'SignUpScreen.lastName'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: lastName,
                          decoration: InputDecoration(
                              hintText: 'SignUpScreen.yourLastName'.tr()),
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
                              contentPadding: const EdgeInsets.only(
                                  left: 0, top: 15, bottom: 15, right: 0),
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
                          selectedItem: provider.selectedTown,
                          items: (filter, infiniteScrollProps) =>
                              provider.towns,
                          itemAsString: (item) => item.name.toString(),
                          onChanged: (value) {
                            provider.setTown(value);
                            provider.setHouse(null);
                            provider.fetchHouses(value.id);
                          },
                          // ignore: no_wildcard_variable_uses
                          compareFn: (item, _) => item.id == _.id,
                          popupProps: PopupProps.dialog(
                            showSearchBox: true,
                            // constraints: const BoxConstraints(minHeight: 400),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownSearch(
                              selectedItem: provider.selectedHouse,
                              items: (filter, infiniteScrollProps) =>
                                  provider.houses,
                              itemAsString: (item) => item.name.toString(),
                              onChanged: (value) {
                                provider.setHouse(value);
                              },
                              // ignore: no_wildcard_variable_uses
                              compareFn: (item, _) => item.id == _.id,
                              popupProps: PopupProps.dialog(
                                showSearchBox: true,
                                // constraints: const BoxConstraints(minHeight: 400),
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
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
                          obscureText: !provider.isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'SignUpScreen.password'.tr(),
                            prefixIcon: Icon(Icons.lock, color: borderColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                provider.isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: borderColor,
                              ),
                              onPressed: () {
                                provider.setIsPasswordVisible(
                                    !provider.isPasswordVisible);
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
                          obscureText: !provider.isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'SignUpScreen.confirmPassword'.tr(),
                            prefixIcon: Icon(Icons.lock, color: borderColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                provider.isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: borderColor,
                              ),
                              onPressed: () {
                                provider.setIsConfirmPasswordVisible(
                                  !provider.isConfirmPasswordVisible,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: p),
                        SizedBox(
                          height: p,
                        ),
                        Button(
                            height: 45,
                            text: 'SignUpScreen.signup'.tr(),
                            onPressed: () => goAuth()),
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
                              width: isMobile
                                  ? width(context) * 0.01
                                  : width(context) * 0.005,
                            ),
                            Center(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                  ),
                                  child: Text(
                                    'SignUpScreen.login'.tr(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
