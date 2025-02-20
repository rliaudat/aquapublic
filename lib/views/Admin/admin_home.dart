import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/edit_profile.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/views/Admin/towns.dart';
import 'package:agua_med/views/Admin/user_registration.dart';
import 'package:agua_med/views/Admin/users/all_users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../_helpers/global.dart';
import '../../_services/storage.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Variables
  var notification = NotificationClass();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String townCount = '-';
  String houseOwnerCount = '-';
  String managerCount = '-';
  String inspectorCount = '-';

  // Functions
  loadData() async {
    firestore.collection('towns').count().get().then((towns) {
      townCount = (towns.count).toString();
      if (mounted) setState(() {});
    });

    firestore.collection('users').where('role', isEqualTo: 'HouseOwner').count().get().then((owners) {
      houseOwnerCount = (owners.count).toString();
      if (mounted) setState(() {});
    });

    firestore.collection('users').where('role', isEqualTo: 'Manager').count().get().then((managers) {
      managerCount = (managers.count).toString();
      if (mounted) setState(() {});
    });

    firestore.collection('users').where('role', isEqualTo: 'Inspector').count().get().then((inspectors) {
      inspectorCount = (inspectors.count).toString();
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    notification.notificationListener();
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return Scaffold(
      appBar: isTablet
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: AppBar(
                backgroundColor: primaryColor,
                title: Text('AdminHomeScreen.adminPanel'.tr()),
                leading: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((value) => setState(() {})),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Row(
                        children: [
                          SizedBox(width: width(context) * 0.01),
                          Container(
                            height: 43,
                            width: 43,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: whiteColor,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: CachedNetworkImage(
                                imageUrl: userSD['profileImageUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Image.asset('assets/avatar.png'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                  isTablet
                      ? AppBar(
                          centerTitle: true,
                          automaticallyImplyLeading: false,
                          title: Text('AdminHomeScreen.dashboard'.tr()),
                          backgroundColor: primaryColor,
                        )
                      : Container(),
                  const SizedBox(height: 20),
                  isTablet
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: p),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                'AdminHomeScreen.dashboard'.tr(),
                                style: TextStyle(color: darkGreyColor, fontSize: 18, height: 1, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  direction: Axis.horizontal,
                                  alignment: WrapAlignment.start,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    AdminDashBoard(
                                      text: 'AdminHomeScreen.towns'.tr(),
                                      image: 'assets/images/town.png',
                                      total: townCount,
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(role: 'HouseOwner', header: 'House Owners')));
                                      },
                                    ),
                                    AdminDashBoard(
                                      text: 'AdminHomeScreen.houseOwners'.tr(),
                                      image: 'assets/images/allUsers.png',
                                      total: houseOwnerCount,
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(role: 'HouseOwner', header: 'House Owners')));
                                      },
                                    ),
                                    AdminDashBoard(
                                      text: 'AdminHomeScreen.inspectors'.tr(),
                                      image: 'assets/images/inspector.png',
                                      total: inspectorCount,
                                      size: 24,
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(role: 'Inspector', header: 'Inspectors')));
                                      },
                                    ),
                                    AdminDashBoard(
                                      text: 'AdminHomeScreen.townManagers'.tr(),
                                      image: 'assets/images/management.png',
                                      total: managerCount,
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(role: 'Manager', header: 'Manager')));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AdminMenu(
                                  image: 'assets/images/allUsers.png',
                                  text: 'AdminHomeScreen.houseOwner'.tr(),
                                  height: p,
                                  size: 40,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(header: 'House Owner', role: 'HouseOwner'))),
                                ),
                                AdminMenu(
                                  image: 'assets/images/inspector.png',
                                  text: 'AdminHomeScreen.inspector'.tr(),
                                  height: 6,
                                  size: 40,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(header: 'Inspector', role: 'Inspector'))),
                                ),
                              ],
                            ),
                            SizedBox(height: p),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AdminMenu(
                                  image: 'assets/images/management.png',
                                  text: 'AdminHomeScreen.townManagers'.tr(),
                                  height: p,
                                  size: 40,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersScreen(header: 'Manager', role: 'Manager'))),
                                ),
                                AdminMenu(
                                  icon: Icons.home_work_rounded,
                                  text: 'AdminHomeScreen.towns'.tr(),
                                  height: 8,
                                  size: 40,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TownsScreen())),
                                ),
                              ],
                            ),
                            SizedBox(height: p),
                            AdminMenu(
                              image: 'assets/images/registeration.png',
                              text: 'AdminHomeScreen.userRegistrations'.tr(),
                              height: p,
                              size: 40,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRegistrationScreen())),
                            ),
                            const SizedBox(height: 20),
                            Button(
                              color: secondaryColor,
                              height: 50,
                              text: 'AdminHomeScreen.logout'.tr(),
                              onPressed: () {
                                Storage.logout();
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                              },
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
