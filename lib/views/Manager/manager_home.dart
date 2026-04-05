import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/edit_profile.dart';
import 'package:agua_med/views/Admin/house.dart';
import 'package:agua_med/views/Admin/invoices.dart';
import 'package:agua_med/views/Admin/user_registration.dart';
import 'package:agua_med/views/Admin/users/all_users.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  var notification = NotificationClass();

  @override
  void initState() {
    notification.notificationListener();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet
            ? null
            : AppBar(
                backgroundColor: primaryColor,
                title: Text("ManagerHomeScreen.townManager".tr())),
        drawer: isTablet ? null : const CustomDrawer(),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTablet
                        ? AppBar(
                            centerTitle: true,
                            automaticallyImplyLeading: false,
                            title: Text('ManagerHomeScreen.townManager'.tr()),
                            backgroundColor: primaryColor,
                          )
                        : Container(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AdminMenu(
                                    image: 'assets/images/allUsers.png',
                                    text: 'ManagerHomeScreen.houseOwner'.tr(),
                                    height: p,
                                    size: 50,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AllUsersScreen(
                                                    role: 'HouseOwner',
                                                    header: 'House Owner'))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AdminMenu(
                                    image: 'assets/images/inspector.png',
                                    text: 'ManagerHomeScreen.inspectors'.tr(),
                                    height: 6,
                                    size: 60,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AllUsersScreen(
                                                    role: 'Inspector',
                                                    header: 'Inspector'))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: p),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AdminMenu(
                                    image: 'assets/images/registeration.png',
                                    text: 'ManagerHomeScreen.userRegistrations'
                                        .tr(),
                                    height: p,
                                    size: 50,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const UserRegistrationScreen())),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AdminMenu(
                                    icon: Icons.home,
                                    text: 'ManagerHomeScreen.houses'.tr(),
                                    height: 8,
                                    size: 55,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HousesScreen(
                                          town: context
                                              .read<UserProvider>()
                                              .user
                                              ?.town['name'],
                                          townID: context
                                              .read<UserProvider>()
                                              .user
                                              ?.town['id'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isTablet)
                            Button(
                              color: secondaryColor,
                              height: 50,
                              text: 'ManagerHomeScreen.logout'.tr(),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                    (route) => false);
                              },
                            ),
                        ],
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
