import 'dart:io';
import 'package:agua_med/_services/user_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/edit_profile_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:flutter/foundation.dart'; // Import foundation.dart

import 'package:agua_med/loading.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController email = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppUser appUser = context.read<UserProvider>().user!;
    firstName.text = appUser.firstName;
    lastName.text = appUser.lastName;
    email.text = appUser.email;
    context
        .read<EditProfileProvider>()
        .setProfileImageURL(appUser.profileImageURL ?? '');
  }

  // Pick image from the gallery
  Future<void> pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        context
            .read<EditProfileProvider>()
            .setWebImage(await pickedFile.readAsBytes());
      } else {
        context
            .read<EditProfileProvider>()
            .setSelectedImage(File(pickedFile.path));
      }
    }
  }

  uploadImage() async {
    var provider = context.read<EditProfileProvider>();
    if (provider.selectedImage == null && provider.webImage == null) return;

    try {
      String filePath =
          'profile_images/${context.read<UserProvider>().user!.uid}.jpg';
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await _storage.ref(filePath).putData(provider.webImage!);
      } else {
        uploadTask =
            await _storage.ref(filePath).putFile(provider.selectedImage!);
      }
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      UserServices.update(
        uid: context.read<UserProvider>().user!.uid,
        data: {'profileImageURL': downloadUrl},
      );
      provider.setProfileImageURL(downloadUrl);
      context.read<UserProvider>().setUser(
            context.read<UserProvider>().user!.copyWith(
                  profileImageURL: downloadUrl,
                ),
          );
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  // Save admin data
  saveAdminData() async {
    var appUser = context.read<UserProvider>().user;
    if (appUser?.firstName != firstName.text ||
        appUser?.lastName != lastName.text) {
      try {
        UserServices.update(
          uid: appUser!.uid,
          data: {'firstName': firstName.text, 'lastName': lastName.text},
        );
        context.read<UserProvider>().setUser(
              context.read<UserProvider>().user!.copyWith(
                    firstName: firstName.text,
                    lastName: lastName.text,
                  ),
            );
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
        drawer: const CustomDrawer(),
        appBar: isTablet
            ? CustomAppBar(
                title: 'EditProfileScreen.editProfile'.tr(),
                showAction: false,
                showButton: true,
              )
            : CustomAppBar(title: 'EditProfileScreen.editProfile'.tr()),
        body:
            Consumer<EditProfileProvider>(builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? p : 0.0,
                          vertical: isTablet ? 16.0 : 0.0),
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
                                          ? provider.webImage != null
                                              ? Image.memory(provider.webImage!,
                                                  fit: BoxFit.cover)
                                              : CachedNetworkImage(
                                                  imageUrl:
                                                      provider.profileImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      Image.asset(
                                                          'assets/avatar.png'),
                                                )
                                          : (provider.selectedImage != null
                                              ? Image.file(
                                                  provider.selectedImage!,
                                                  fit: BoxFit.cover)
                                              : CachedNetworkImage(
                                                  imageUrl:
                                                      provider.profileImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      Image.asset(
                                                          'assets/avatar.png'))),
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
                              hintText:
                                  'EditProfileScreen.Enteryourfirstname'.tr(),
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
                            decoration: InputDecoration(
                                hintText:
                                    'EditProfileScreen.Enteryourlastname'.tr()),
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
                              hintText:
                                  'EditProfileScreen.Enteryouremailaddress'
                                      .tr(),
                              prefixIcon: Icon(Icons.email, color: borderColor),
                            ),
                          ),
                          SizedBox(height: isTablet ? p : 170),
                          Button(
                            height: 50,
                            width: width(context),
                            text: 'EditProfileScreen.Save'.tr(),
                            onPressed: () async {
                              showLoader(context,
                                  'EditProfileScreen.Justamoment'.tr());

                              if (provider.selectedImage != null ||
                                  provider.webImage != null) {
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
          );
        }),
      ),
    );
  }
}
