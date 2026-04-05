import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Admin/invoices.dart';
import 'package:agua_med/views/Admin/towns.dart';
import 'package:agua_med/views/Admin/user_registration.dart';
import 'package:agua_med/views/Admin/users/all_users.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Inspector/search_house_bill.dart';
import 'package:agua_med/edit_profile.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:agua_med/views/User/web_dashboard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../theme.dart';
import '../_helpers/global.dart';
import 'Reuseable.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    bool isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    AppUser user = context.read<UserProvider>().user!;
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      backgroundColor: whiteColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // =================== Header Area ===================
            UserAccountsDrawerHeader(
              accountName: Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(user.email),
              currentAccountPicture: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: whiteColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CachedNetworkImage(
                    imageUrl: user.profileImageURL ??
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHZqj-XReJ2R76nji51cZl4ETk6-eHRmZBRw&s",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/avatar.png'),
                  ),
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: const [0.0, 1.0],
                  colors: [primaryColor, secondaryColor],
                ),
              ),
            ),

            // =================== Drawer Items ===================
            DrawerTiles(
              text: 'CustomDrawer.dashboard'.tr(),
              onTap: () {
                if (mounted) setState(() => selectedTile = 0);
                if (!isTablet) pop(context);

                if (user.role == 'Admin') {
                  Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminHomeScreen()))
                      .then((value) {
                    if (mounted) setState(() => selectedTile = 0);
                  });
                } else if (user.role == 'Manager') {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
             
                          builder: (context) => 
                          // isDesktop
                          //     ? const UserWebDashboardPage()
                          //     : 
                              const ManagerHomeScreen())).then((value) {
                    if (mounted) setState(() => selectedTile = 0);
                  });
                } else if (user.role == 'Inspector') {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const InspectorHomeScreen())).then((value) {
                    if (mounted) setState(() => selectedTile = 0);
                  });
                } else {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          //  isDesktop
                          //     ? const UserWebDashboardPage()
                          //     : 
                              const HomeScreen())).then((value) {
                    if (mounted) setState(() => selectedTile = 0);
                  });
                }
              },
              selected: selectedTile == 0,
              imagePath: 'assets/images/adminDash.png',
              rowWidth:
                  isTablet ? width(context) * 0.021 : width(context) * 0.05,
              size: 18,
            ),

            if (user.role == 'Admin' || user.role == 'Manager')
              DrawerTiles(
                text: 'CustomDrawer.houseOwners'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 1);
                  if (!isTablet) pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllUsersScreen(
                              header: 'House Owner',
                              role: 'HouseOwner'))).then((value) {
                    if (mounted) setState(() => selectedTile = 1);
                  });
                },
                selected: selectedTile == 1,
                imagePath: 'assets/images/allUsers.png',
                rowWidth:
                    isTablet ? width(context) * 0.021 : width(context) * 0.05,
                size: 18,
              ),
            if (user.role == 'Admin' || user.role == 'Manager')
              DrawerTiles(
                text: 'CustomDrawer.inspectors'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 2);
                  if (!isTablet) pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllUsersScreen(
                              header: 'Inspector',
                              role: 'Inspector'))).then((value) {
                    if (mounted) setState(() => selectedTile = 2);
                  });
                },
                imagePath: 'assets/images/inspector.png',
                rowWidth:
                    isTablet ? width(context) * 0.017 : width(context) * 0.041,
                size: 22,
                selected: selectedTile == 2,
              ),
            if (user.role == 'Admin' || user.role == 'Manager')
              DrawerTiles(
                text: 'CustomDrawer.userRegistrations'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 3);
                  if (!isTablet) pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const UserRegistrationScreen())).then((value) {
                    if (mounted) setState(() => selectedTile = 3);
                  });
                },
                imagePath: 'assets/images/registeration.png',
                rowWidth:
                    isTablet ? width(context) * 0.018 : width(context) * 0.04,
                size: 22,
                selected: selectedTile == 3,
              ),
            if (user.role == 'Admin')
              DrawerTiles(
                text: 'CustomDrawer.towns'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 4);
                  if (!isTablet) pop(context);
                  Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TownsScreen()))
                      .then((value) {
                    if (mounted) setState(() => selectedTile = 4);
                  });
                },
                icon: Icons.home_work,
                rowWidth:
                    isTablet ? width(context) * 0.018 : width(context) * 0.04,
                size: 22,
                selected: selectedTile == 4,
              ),
            if (user.role == 'Admin')
              DrawerTiles(
                text: 'CustomDrawer.townManagers'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 5);
                  if (!isTablet) pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllUsersScreen(
                              header: 'Town Manager',
                              role: 'Manager'))).then((value) {
                    if (mounted) setState(() => selectedTile = 5);
                  });
                },
                imagePath: 'assets/images/management.png',
                rowWidth:
                    isTablet ? width(context) * 0.0185 : width(context) * 0.039,
                size: 22,
                selected: selectedTile == 5,
              ),
            // if (user.role == 'Admin')
            //   DrawerTiles(
            //     text: 'CustomDrawer.readings'.tr(),
            //     onTap: () {
            //       if (mounted) setState(() => selectedTile = 8);
            //       pop(context);
            //       Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => const UserWebDashboardPage(),
            //         ),
            //       ).then(
            //         (value) {
            //           if (mounted) setState(() => selectedTile = 8);
            //         },
            //       );
            //     },
            //     imagePath: 'assets/images/reading.png',
            //     rowWidth:
            //         isTablet ? width(context) * 0.02 : width(context) * 0.05,
            //     size: 20,
            //     selected: selectedTile == 8,
            //   ),
            if (user.role == 'Admin' || user.role == 'Manager')
              DrawerTiles(
                text: 'CustomDrawer.invoices'.tr(),
                onTap: () {
                  if (mounted) setState(() => selectedTile = 6);
                  if (!isTablet) pop(context);
                  if (user.role == 'Admin' || user.role == 'Manager') {
                    Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const InvoiceScreen()))
                        .then((value) {
                      if (mounted) setState(() => selectedTile = 6);
                    });
                  } else {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const SearchHouseScreen())).then((value) {
                      if (mounted) setState(() => selectedTile = 6);
                    });
                  }
                },
                imagePath: 'assets/images/invoice.png',
                rowWidth:
                    isTablet ? width(context) * 0.02 : width(context) * 0.05,
                size: 20,
                selected: selectedTile == 6,
              ),
            DrawerTiles(
              text: 'CustomDrawer.editProfile'.tr(),
              onTap: () {
                if (mounted) setState(() => selectedTile = 7);
                if (!isTablet) pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((value) {
                  if (mounted) setState(() => selectedTile = 7);
                });
              },
              icon: Icons.edit,
              rowWidth:
                  isTablet ? width(context) * 0.02 : width(context) * 0.047,
              size: 20,
              selected: selectedTile == 7,
            ),

            // if (!kIsWeb)
            //   DrawerTiles(
            //     text: 'CustomDrawer.rateUs'.tr(),
            //     onTap: () {
            //       if (mounted) setState(() => selectedTile = 8);
            //     },
            //     icon: Icons.star_rate,
            //     rowWidth:
            //         isTablet ? width(context) * 0.017 : width(context) * 0.038,
            //     size: 22,
            //     selected: selectedTile == 8,
            //   ),

            // DrawerTiles(
            //   text: 'CustomDrawer.privacyAndPolicy'.tr(),
            //   onTap: () {
            //     if (mounted) setState(() => selectedTile = 9);
            //     pop(context);
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) =>
            //                 const PrivacyAndPolicyScreen())).then((value) {
            //       if (mounted) setState(() => selectedTile = 9);
            //     });
            //   },
            //   icon: Icons.privacy_tip,
            //   rowWidth:
            //       isTablet ? width(context) * 0.017 : width(context) * 0.036,
            //   size: 20,
            //   padding: 2,
            //   selected: selectedTile == 9,
            // ),
            // DrawerTiles(
            //   text: 'CustomDrawer.termsAndConditions'.tr(),
            //   onTap: () {
            //     if (mounted) setState(() => selectedTile = 10);
            //     pop(context);
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) =>
            //                 const TermsAndConditionScreen())).then((value) {
            //       if (mounted) setState(() => selectedTile = 10);
            //     });
            //   },
            //   imagePath: 'assets/images/terms.png',
            //   rowWidth:
            //       isTablet ? width(context) * 0.015 : width(context) * 0.027,
            //   size: 22,
            //   padding: 3,
            //   selected: selectedTile == 10,
            // ),
            DrawerTiles(
              text: 'CustomDrawer.logout'.tr(),
              onTap: () async {
                context.read<UserProvider>().setUser(null);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              imagePath: 'assets/images/logout.png',
              rowWidth:
                  isTablet ? width(context) * 0.015 : width(context) * 0.029,
              size: 22,
              padding: 3,
              selected: false,
            ),
            SizedBox(height: isTablet ? 20 : 0),
          ],
        ),
      ),
    );
  }
}
