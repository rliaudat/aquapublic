import 'dart:io';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_helpers/encrypption.dart';
import 'package:agua_med/bloc/authentication/authentication_bloc.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/create_owner_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../_services/auth_services.dart';
import '../../../loading.dart';

class CreateOwnerScreen extends StatefulWidget {
  final String role;
  final String header;
  const CreateOwnerScreen(
      {super.key, required this.role, required this.header});

  @override
  State<CreateOwnerScreen> createState() => _CreateOwnerScreenState();
}

class _CreateOwnerScreenState extends State<CreateOwnerScreen> {
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
  var role = TextEditingController();
  var confirmPassword = TextEditingController();

  AuthService authService = AuthService();

  goAuth() async {
    unFocus(context);
    email.text = email.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        email.text.isEmpty ||
        !EmailValidator.validate(email.text) ||
        phone.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      if (firstName.text.isEmpty) {
        showToast(context,
            msg: 'CreateOwnerScreen.firstNameRequired'.tr(), duration: 2);
      }
      if (lastName.text.isEmpty) {
        showToast(context, msg: 'CreateOwnerScreen.lastNameRequired'.tr());
      }
      if (email.text.isEmpty) {
        showToast(context, msg: 'CreateOwnerScreen.emailRequired'.tr());
      }
      if (EmailValidator.validate(email.text) == false) {
        showToast(context, msg: 'CreateOwnerScreen.invalidEmailAddress'.tr());
      }
      if (phone.text.isEmpty) {
        showToast(context, msg: 'CreateOwnerScreen.phoneRequired'.tr());
      }
      if (password.text.isEmpty) {
        showToast(context, msg: 'CreateOwnerScreen.passwordRequired'.tr());
      }
      if (confirmPassword.text.isEmpty) {
        showToast(context,
            msg: 'CreateOwnerScreen.confirmPasswordRequired'.tr());
      }
      return;
    }
    if (password.text != confirmPassword.text) {
      showToast(context, msg: 'CreateOwnerScreen.passwordsDoNotMatch'.tr());
      return;
    }
    if (widget.role == 'Inspector') {
      final selectedTowns = context.read<CreateOwnerProvider>().selectedTown;
      if (selectedTowns == null || (selectedTowns is List && selectedTowns.isEmpty)) {
        showToast(context, msg: 'CreateOwnerScreen.townRequired'.tr());
        return;
      }
    }
    doCreate();
  }

  doCreate() {
    showLoader(context, 'CreateOwnerScreen.justAMoment'.tr());
    authService
        .createUser(
      user: AppUser(
        uid: '',
        firstName: firstName.text,
        lastName: lastName.text,
        email: email.text,
        phoneNumber: phone.text,
        isoCode: isoCode,
        dialCode: dialCode,
        role: role.text,
        status: 'active',
        isDelete: false,
        town: context.read<CreateOwnerProvider>().selectedTown,
        house: context.read<CreateOwnerProvider>().selectedHouse,
        encryptedPassword: '',
        iv: '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      ),
      password: password.text,
      image: context.read<CreateOwnerProvider>().profileImage,
    )
        .then((_) {
      BlocProvider.of<AuthenticationBloc>(context).add(LoginByEmail(
        email: context.read<UserProvider>().user!.email,
        password: decryptPass(
          text: context.read<UserProvider>().user!.encryptedPassword,
          iv: context.read<UserProvider>().user!.iv,
          key: 'SECRET_KEY',
        ),
        platform: context.read<UserProvider>().user!.email,
        token: context.read<UserProvider>().user!.fcmToken,
      ));
      pop(context);
      // ignore: no_wildcard_variable_uses
      if (_ == 'success') {
        showToast(context,
            msg:
                '${widget.header} ${'CreateOwnerScreen.successfullyCreated'.tr()}');
        pop(context);
      } else {
        // ignore: use_build_context_synchronously, no_wildcard_variable_uses
        showToast(context, msg: _);
      }
    });
  }

  @override
  void initState() {
    context.read<CreateOwnerProvider>().fetchTowns(
          context.read<UserProvider>().user!,
        );
    role.text = widget.role;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
        onTap: () => unFocus(context),
        child:
            Consumer<CreateOwnerProvider>(builder: (context, provider, child) {
          return Scaffold(
            appBar: isTablet
                ? CustomAppBar(title: 'Create ${widget.header}')
                : CustomAppBar(title: 'Create ${widget.header}'),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isTablet ? 20 : 0),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: p),
                          child: Center(
                            child: Container(
                              width: isTablet ? 400 : width(context),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isTablet
                                      ? darkGreyColor
                                      : transparentColor,
                                  width: isTablet ? 0 : 0.5,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? p : 0.0,
                                    vertical: isTablet ? 16.0 : 0.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: isTablet ? 0 : 30),
                                    Stack(
                                      children: [
                                        Center(
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: provider.profileImage !=
                                                        null
                                                    ? Image.file(
                                                        provider.profileImage!,
                                                        fit: BoxFit.cover)
                                                    : Image.asset(
                                                        'assets/avatar.png')),
                                          ),
                                        ),
                                        Positioned.fill(
                                          top: 70,
                                          left: 65,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final pickedFile =
                                                  await ImagePicker().pickImage(
                                                      source:
                                                          ImageSource.gallery);
                                              if (pickedFile != null) {
                                                provider.setProfileImage(
                                                  File(
                                                    pickedFile.path,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              height: 20,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: whiteColor,
                                                    width: 3),
                                              ),
                                              child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 18,
                                                  color: whiteColor),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      'CreateOwnerScreen.firstName'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: firstName,
                                      decoration: InputDecoration(
                                        hintText:
                                            'CreateOwnerScreen.yourFirstName'
                                                .tr(),
                                      ),
                                    ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.lastName'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: lastName,
                                      decoration: InputDecoration(
                                          hintText:
                                              'CreateOwnerScreen.yourLastName'
                                                  .tr()),
                                    ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.email'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: email,
                                      decoration: InputDecoration(
                                        hintText:
                                            'CreateOwnerScreen.email'.tr(),
                                        prefixIcon: Icon(Icons.email,
                                            color: borderColor),
                                      ),
                                    ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.phoneNumber'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                        autoValidateMode:
                                            AutovalidateMode.disabled,
                                        onInputChanged: (PhoneNumber number) {
                                          phone.text = number.phoneNumber!;
                                          isoCode = number.isoCode!;
                                          dialCode = number.dialCode!;
                                        },
                                        searchBoxDecoration: InputDecoration(
                                          hintText:
                                              'CreateOwnerScreen.search'.tr(),
                                        ),
                                        selectorConfig: const SelectorConfig(
                                          selectorType: PhoneInputSelectorType
                                              .BOTTOM_SHEET,
                                          leadingPadding: 0,
                                          trailingSpace: false,
                                          setSelectorButtonAsPrefixIcon: false,
                                          useBottomSheetSafeArea: true,
                                        ),
                                        inputDecoration: const InputDecoration(
                                          hintText: 'Phone No',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.only(
                                            left: 0,
                                            top: 15,
                                            bottom: 15,
                                            right: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.town'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    (widget.role == 'Inspector')
                                        ? DropdownSearch.multiSelection(
                                            items:
                                                (filter, infiniteScrollProps) =>
                                                    provider.towns,
                                            itemAsString: (item) =>
                                                item['name'].toString(),
                                            onChanged: (value) {
                                              provider.setTown(value);
                                            },
                                            compareFn: (item, _) =>
                                                // ignore: no_wildcard_variable_uses
                                                item['id'] == _['id'],
                                            popupProps:
                                                PopupPropsMultiSelection.dialog(
                                              showSearchBox: true,
                                              searchFieldProps: TextFieldProps(
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'CreateOwnerScreen.search'
                                                          .tr(),
                                                  prefixIcon:
                                                      const Icon(Icons.search),
                                                ),
                                              ),
                                              fit: FlexFit.loose,
                                              title: Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Text(
                                                  'CreateOwnerScreen.selectATown'
                                                      .tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          )
                                        : DropdownSearch(
                                            selectedItem: provider.selectedTown,
                                            items:
                                                (filter, infiniteScrollProps) =>
                                                    provider.towns,
                                            itemAsString: (item) =>
                                                item['name'].toString(),
                                            onChanged: (value) {
                                              provider.setTown(value);
                                              provider.setHouse(null);
                                              provider.fetchHouses(value['id']);
                                            },
                                            compareFn: (item, _) =>
                                                // ignore: no_wildcard_variable_uses
                                                item['id'] == _['id'],
                                            popupProps: PopupProps.dialog(
                                              showSearchBox: true,
                                              searchFieldProps: TextFieldProps(
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'CreateOwnerScreen.search'
                                                          .tr(),
                                                  prefixIcon:
                                                      const Icon(Icons.search),
                                                ),
                                              ),
                                              fit: FlexFit.loose,
                                              title: Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Text(
                                                  'CreateOwnerScreen.selectATown'
                                                      .tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
                                    if (widget.role == 'HouseOwner')
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: p),
                                          Text(
                                            'CreateOwnerScreen.house'.tr(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownSearch(
                                            selectedItem:
                                                provider.selectedHouse,
                                            items:
                                                (filter, infiniteScrollProps) =>
                                                    provider.houses,
                                            itemAsString: (item) =>
                                                item['name'].toString(),
                                            onChanged: (value) {
                                              provider.setHouse(value);
                                            },
                                            compareFn: (item, _) =>
                                                // ignore: no_wildcard_variable_uses
                                                item['id'] == _['id'],
                                            popupProps: PopupProps.dialog(
                                              showSearchBox: true,
                                              searchFieldProps: TextFieldProps(
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'CreateOwnerScreen.search'
                                                          .tr(),
                                                  prefixIcon:
                                                      const Icon(Icons.search),
                                                ),
                                              ),
                                              fit: FlexFit.loose,
                                              title: Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Text(
                                                  'CreateOwnerScreen.selectAHouse'
                                                      .tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.role'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: role,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.account_circle,
                                          color: borderColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: p),
                                    Text(
                                      'CreateOwnerScreen.password'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: password,
                                      obscureText: !provider.isPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText:
                                            'CreateOwnerScreen.password'.tr(),
                                        prefixIcon: Icon(
                                          Icons.lock,
                                          color: borderColor,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            provider.isPasswordVisible
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
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
                                    Text(
                                      'CreateOwnerScreen.confirmPassword'.tr(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: confirmPassword,
                                      obscureText:
                                          !provider.isConfirmPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText:
                                            'CreateOwnerScreen.confirmPassword'
                                                .tr(),
                                        prefixIcon: Icon(Icons.lock,
                                            color: borderColor),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            provider.isConfirmPasswordVisible
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: borderColor,
                                          ),
                                          onPressed: () {
                                            provider
                                                .setIsConfirmPasswordVisible(
                                              !provider
                                                  .isConfirmPasswordVisible,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) =>
                                          provider.setUpdateHover(true),
                                      onExit: (_) =>
                                          provider.setUpdateHover(false),
                                      child: Button(
                                          color: provider.updateHover
                                              ? primaryColor
                                              : secondaryColor,
                                          height: 50,
                                          width: width(context),
                                          text: 'CreateOwnerScreen.create'.tr(),
                                          onPressed: () {
                                            goAuth();
                                          }),
                                    ),
                                    SizedBox(
                                      height: isTablet ? 0 : 30,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 0)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }));
  }
}
