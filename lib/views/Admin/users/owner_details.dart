import 'dart:io';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ephone_field/ephone_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../_services/auth_Services.dart';
import '../../../loading.dart';

class OwnerDetailsScreen extends StatefulWidget {
  final dynamic data;
  final String role;
  final String header;
  const OwnerDetailsScreen({
    super.key,
    required this.data,
    required this.role,
    required this.header,
  });

  @override
  State<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

class _OwnerDetailsScreenState extends State<OwnerDetailsScreen> {
  List towns = [];
  List houses = [];
  dynamic selectedTown;
  dynamic selectedHouse;

  var email = TextEditingController();
  PhoneNumber phoneNumber = PhoneNumber(isoCode: Country.argentina.alpha2, dialCode: '+${Country.argentina.dialCode}', phoneNumber: '');
  var phone = TextEditingController();
  dynamic isoCode;
  dynamic dialCode;
  var firstName = TextEditingController();
  var lastName = TextEditingController();
  bool updateHover = false;
  AuthService authService = AuthService();
  File? selectedProfileImage;

  // Functions
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

  pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedProfileImage = File(pickedFile.path);
      if (mounted) setState(() {});
    }
  }

  goAuth() async {
    unFocus(context);
    email.text = email.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty || !EmailValidator.validate(email.text) || phone.text.isEmpty || selectedTown == null) {
      if (firstName.text.isEmpty) {
        showToast(context, msg: 'OwnerDetailsScreen.firstNameRequired'.tr(), duration: 2);
      }
      if (lastName.text.isEmpty) {
        showToast(context, msg: 'OwnerDetailsScreen.lastNameRequired'.tr());
      }
      if (email.text.isEmpty) {
        showToast(context, msg: 'OwnerDetailsScreen.emailRequired'.tr());
      }
      if (EmailValidator.validate(email.text) == false) {
        showToast(context, msg: 'OwnerDetailsScreen.invalidEmailAddress'.tr());
      }
      if (phone.text.isEmpty) {
        showToast(context, msg: 'OwnerDetailsScreen.phoneRequired'.tr());
      }
      if (selectedTown == null) {
        showToast(context, msg: 'OwnerDetailsScreen.townRequired'.tr());
      }
      return;
    }
    doUpdate();
  }

  doUpdate() {
    showLoader(context, 'OwnerDetailsScreen.justAMoment'.tr());
    var obj = {
      'id': widget.data['id'],
      'firstName': firstName.text,
      'lastName': lastName.text,
      'email': email.text,
      'phone': phone.text,
      'town': selectedTown,
      'house': selectedHouse,
      'profileImage': selectedProfileImage,
    };
    authService.updateUser(obj).then((_) {
      pop(context);
      if (_ == 'success') {
        showToast(context, msg: '${widget.header} OwnerDetailsScreen.successfullyCreated'.tr());
        pop(context);
      } else {
        showToast(context, msg: _);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTowns();
    firstName.text = widget.data['firstName'];
    lastName.text = widget.data['lastName'];
    email.text = widget.data['email'];
    phone.text = widget.data['phone'];
    phoneNumber = PhoneNumber(isoCode: widget.data['isoCode'], dialCode: widget.data['dialCode'], phoneNumber: widget.data['phone']);
    isoCode = widget.data['isoCode'];
    dialCode = widget.data['dialCode'];
    selectedTown = widget.data['town'];
    selectedHouse = widget.data['house'];
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : CustomAppBar(title: '${widget.header} Details'),
        body: Row(
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTablet ? CustomAppBar(title: '${widget.header} Details') : Container(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Center(
                        child: Container(
                          width: isTablet ? 400 : width(context),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isTablet ? borderColor : transparentColor,
                                width: isTablet ? 0 : 1,
                              )),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? p : 0.0, vertical: isTablet ? 16.0 : 0.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 30,
                                ),
                                Stack(
                                  children: [
                                    Center(
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: pickImage,
                                          child: Container(
                                            height: 100,
                                            width: 100,
                                            decoration: BoxDecoration(border: Border.all(color: borderColor, width: 1), shape: BoxShape.circle),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(100),
                                              child: selectedProfileImage != null
                                                  ? Image.file(
                                                      selectedProfileImage!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : CachedNetworkImage(
                                                      imageUrl: widget.data['profileImageUrl'] ?? "",
                                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                      errorWidget: (context, url, error) => Image.asset('assets/avatar.png'),
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                        top: 70,
                                        left: 65,
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: whiteColor,
                                                width: 3,
                                              )),
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            size: 18,
                                            color: whiteColor,
                                          ),
                                        ))
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'OwnerDetailsScreen.firstName'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: firstName,
                                  decoration: InputDecoration(hintText: 'OwnerDetailsScreen.john'.tr()),
                                ),
                                SizedBox(height: p),
                                Text(
                                  'OwnerDetailsScreen.lastName'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: lastName,
                                  decoration: InputDecoration(hintText: 'OwnerDetailsScreen.doe'.tr()),
                                ),
                                SizedBox(height: p),
                                Text(
                                  'OwnerDetailsScreen.email'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: email,
                                  decoration: InputDecoration(
                                    hintText: 'OwnerDetailsScreen.johndoeEmail'.tr(),
                                    prefixIcon: Icon(Icons.email, color: borderColor),
                                  ),
                                ),
                                SizedBox(height: p),
                                Text(
                                  'OwnerDetailsScreen.phoneNumber'.tr(),
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
                                      hintText: 'OwnerDetailsScreen.search'.tr(),
                                    ),
                                    selectorConfig: const SelectorConfig(
                                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                                      leadingPadding: 0,
                                      trailingSpace: false,
                                      setSelectorButtonAsPrefixIcon: false,
                                      useBottomSheetSafeArea: true,
                                    ),
                                    inputDecoration: InputDecoration(
                                      hintText: 'OwnerDetailsScreen.phoneNo'.tr(),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.only(
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
                                  'OwnerDetailsScreen.town'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                (widget.role == 'Inspector')
                                    ? DropdownSearch.multiSelection(
                                        selectedItems: selectedTown,
                                        items: (filter, infiniteScrollProps) => towns,
                                        itemAsString: (item) => item['name'].toString(),
                                        onChanged: (value) {
                                          selectedTown = value;
                                        },
                                        compareFn: (item, _) => item['id'] == _['id'],
                                        popupProps: PopupPropsMultiSelection.dialog(
                                          showSearchBox: true,
                                          searchFieldProps: TextFieldProps(
                                            decoration: InputDecoration(
                                              labelText: 'OwnerDetailsScreen.search'.tr(),
                                              prefixIcon: const Icon(Icons.search),
                                            ),
                                          ),
                                          fit: FlexFit.loose,
                                          title: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Text(
                                              'OwnerDetailsScreen.selectATown'.tr(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      )
                                    : DropdownSearch(
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
                                          searchFieldProps: TextFieldProps(
                                            decoration: InputDecoration(
                                              labelText: 'OwnerDetailsScreen.search'.tr(),
                                              prefixIcon: const Icon(Icons.search),
                                            ),
                                          ),
                                          fit: FlexFit.loose,
                                          title: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Text(
                                              'OwnerDetailsScreen.selectATown'.tr(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      ),
                                if (widget.role == 'HouseOwner')
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: p),
                                      Text(
                                        'OwnerDetailsScreen.house'.tr(),
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
                                          searchFieldProps: TextFieldProps(
                                            decoration: InputDecoration(
                                              labelText: 'OwnerDetailsScreen.search'.tr(),
                                              prefixIcon: const Icon(Icons.search),
                                            ),
                                          ),
                                          fit: FlexFit.loose,
                                          title: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Text(
                                              'OwnerDetailsScreen.selectAHouse'.tr(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                const SizedBox(height: 20),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() => updateHover = true),
                                  onExit: (_) => setState(() => updateHover = false),
                                  child: Button(
                                    color: updateHover ? primaryColor : secondaryColor,
                                    height: 50,
                                    width: width(context),
                                    text: 'OwnerDetailsScreen.update'.tr(),
                                    onPressed: () => goAuth(),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 0 : 20)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
