import 'dart:io';
import 'package:flutter/foundation.dart'; // Import foundation.dart

import 'package:agua_med/_services/storage.dart';
import 'package:agua_med/loading.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

import 'Components/Drawer.dart';
import 'Components/Reuseable.dart';
import 'theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController email = TextEditingController();

  String profileImageUrl = "";
  File? selectedImage;
  Uint8List? webImage;

  @override
  void initState() {
    super.initState();
    firstName.text = userSD['firstName'] ?? '';
    lastName.text = userSD['lastName'] ?? '';
    email.text = userSD['email'] ?? '';
    profileImageUrl = userSD['profileImageUrl'] ?? '';
  }

  // Pick image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        webImage = await pickedFile.readAsBytes();
      } else {
        selectedImage = File(pickedFile.path); // Update with selected image
      }
      if (mounted) setState(() {});
    }
  }

  uploadImage() async {
    if (selectedImage == null && webImage == null) return;

    try {
      String filePath = 'profile_images/${userSD['id']}.jpg';
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await _storage.ref(filePath).putData(webImage!);
      } else {
        uploadTask = await _storage.ref(filePath).putFile(selectedImage!);
      }
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      await _firestore.collection('users').doc(userSD['id']).update({'profileImageUrl': downloadUrl});
      profileImageUrl = downloadUrl;
      userSD['profileImageUrl'] = downloadUrl;
      if (mounted) setState(() {});
      await Storage.setLogin(userSD);
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  // Save admin data
  saveAdminData() async {
    if (userSD['firstName'] != firstName.text || userSD['lastName'] != lastName.text) {
      try {
        await _firestore.collection('users').doc(userSD['id']).update({'firstName': firstName.text, 'lastName': lastName.text});
        userSD['firstName'] = firstName.text;
        userSD['lastName'] = lastName.text;
        if (mounted) setState(() {});
        await Storage.setLogin(userSD);
        showToast(context, msg: 'EditProfileScreen.Profilehasbeenupdated'.tr());
      } catch (e) {
        showToast(context, msg: 'EditProfileScreen.Failedtoupdateprofile'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : CustomAppBar(title: 'EditProfileScreen.editProfile'.tr()),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTablet ? CustomAppBar(title: 'EditProfileScreen.editProfile'.tr(), showAction: false, showButton: false) : Container(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Center(
                        child: Container(
                          width: isTablet ? 400 : width(context),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isTablet ? darkGreyColor : transparentColor,
                              width: isTablet ? 0 : 0.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? p : 0.0, vertical: isTablet ? 16.0 : 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Stack(
                                  children: [
                                    Center(
                                      child: SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: kIsWeb
                                              ? webImage != null
                                                  ? Image.memory(webImage!, fit: BoxFit.cover)
                                                  : CachedNetworkImage(
                                                      imageUrl: profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) => Image.asset('assets/avatar.png'),
                                                    )
                                              : (selectedImage != null
                                                  ? Image.file(selectedImage!, fit: BoxFit.cover)
                                                  : CachedNetworkImage(imageUrl: profileImageUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => Image.asset('assets/avatar.png'))),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      top: 70,
                                      left: 65,
                                      child: GestureDetector(
                                        onTap: () => pickImage(),
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: whiteColor,
                                              width: 3,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            size: 18,
                                            color: whiteColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 30 : 50),
                              Text(
                                'EditProfileScreen.FirstName'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: firstName,
                                decoration: InputDecoration(
                                  hintText: 'EditProfileScreen.Enteryourfirstname'.tr(),
                                ),
                              ),
                              SizedBox(height: p),
                              Text(
                                'EditProfileScreen.LastName'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: lastName,
                                decoration: InputDecoration(hintText: 'EditProfileScreen.Enteryourlastname'.tr()),
                              ),
                              SizedBox(height: p),
                              Text(
                                'EditProfileScreen.Email'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: email,
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: 'EditProfileScreen.Enteryouremailaddress'.tr(),
                                  prefixIcon: Icon(Icons.email, color: borderColor),
                                ),
                              ),
                              SizedBox(height: isTablet ? p : 170),
                              Button(
                                height: 50,
                                width: width(context),
                                text: 'EditProfileScreen.Save'.tr(),
                                onPressed: () async {
                                  showLoader(context, 'EditProfileScreen.Justamoment'.tr());

                                  if (selectedImage != null || webImage != null) {
                                    await uploadImage();
                                  }
                                  await saveAdminData();
                                  pop(context);
                                },
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
          ],
        ),
      ),
    );
  }
}
