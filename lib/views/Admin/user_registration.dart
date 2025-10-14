import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_services/admin_Services.dart';
import 'package:agua_med/_services/user_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/providers/user_registration_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  TextEditingController searchController = TextEditingController();

  AdminService adminService = AdminService();

  @override
  void initState() {
    context.read<UserRegistrationProvider>().loadTowns(
          context.read<UserProvider>().user!.role,
          context.read<UserProvider>().user!.town,
        );
    super.initState();
  }

  registration(String userId, String role) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'role': role,
        'status': 'active',
      });
      showToast(context,
          msg: 'userRegistrationScreen.userRegisteredSuccessfully'.tr());
    } catch (e) {
      debugPrint("Error updating user role: $e");
    }
  }

  Widget townPipe(data) {
    List towns = [];
    var town = data.town ?? {"name": "No Town"};
    towns.add(town);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          towns.length,
          (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: EdgeInsets.only(right: index == towns.length - 1 ? 0 : 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: textColor,
              ),
              child: Text(
                towns[index]['name'],
                style: TextStyle(
                    color: blackColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Consumer<UserRegistrationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            drawer: isTablet ? Container() : const CustomDrawer(),
            appBar: isTablet
                ? AppBar(
                    centerTitle: true,
                    automaticallyImplyLeading: true,
                    title:
                        Text('userRegistrationScreen.userRegistrations'.tr()),
                    backgroundColor: primaryColor,
                  )
                : CustomAppBar(
                    title: 'userRegistrationScreen.userRegistrations'.tr()),
            body: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: p),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 30),
                                      isTablet
                                          ? Container(
                                              height: 95,
                                              width: width(context),
                                              decoration: BoxDecoration(
                                                color: greyColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        radius),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 8),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Town',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    darkGreyColor),
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          Container(
                                                            height: 46,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          radius),
                                                              border:
                                                                  Border.all(
                                                                color:
                                                                    borderColor,
                                                              ),
                                                            ),
                                                            child:
                                                                DropdownButtonFormField(
                                                              items: provider
                                                                  .towns
                                                                  .map((town) {
                                                                return DropdownMenuItem(
                                                                  value: town,
                                                                  child: Text(town[
                                                                      'name']),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                provider
                                                                    .setTown(
                                                                  value as Map<
                                                                      String,
                                                                      dynamic>,
                                                                );
                                                              },
                                                              value: provider
                                                                  .selectedTown,
                                                              decoration:
                                                                  InputDecoration(
                                                                filled: true,
                                                                fillColor:
                                                                    Colors.grey[
                                                                        200],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: width(context) *
                                                            0.01),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'House',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    darkGreyColor),
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          SizedBox(
                                                            height: 45,
                                                            child: TextField(
                                                              controller:
                                                                  searchController,
                                                              decoration:
                                                                  InputDecoration(
                                                                hintText:
                                                                    "Search by house Id",
                                                                prefixIcon:
                                                                    Icon(
                                                                  Icons
                                                                      .search_rounded,
                                                                  size: 18,
                                                                  color:
                                                                      borderColor,
                                                                ),
                                                              ),
                                                              onChanged:
                                                                  (value) {
                                                                provider
                                                                    .setSearchQuery(
                                                                        value);
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: width(context) *
                                                            0.01),
                                                    MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      onEnter: (_) => provider
                                                          .setSearchHover(true),
                                                      onExit: (_) => provider
                                                          .setSearchHover(
                                                              false),
                                                      child: Button(
                                                          color: provider
                                                                  .searchHover
                                                              ? primaryColor
                                                              : secondaryColor,
                                                          borderRadius: radius,
                                                          height: 45,
                                                          width:
                                                              width(context) /
                                                                  9,
                                                          text: 'Search',
                                                          fontSize:
                                                              width(context) *
                                                                  0.0115,
                                                          onPressed: () {
                                                            provider.setSearchQuery(
                                                                searchController
                                                                    .text);
                                                          }),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                Flexible(
                                                  child: SizedBox(
                                                    height: 45,
                                                    child: TextField(
                                                      controller:
                                                          searchController,
                                                      onChanged: (value) {
                                                        provider.setSearchQuery(
                                                            value);
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        hintText:
                                                            "userRegistrationScreen.searchByNameOrTownId"
                                                                .tr(),
                                                        prefixIcon: Icon(
                                                            Icons
                                                                .search_rounded,
                                                            size: 18,
                                                            color: borderColor),
                                                        suffixIcon:
                                                            searchController
                                                                    .text
                                                                    .isNotEmpty
                                                                ? IconButton(
                                                                    icon: Icon(
                                                                        Icons
                                                                            .clear,
                                                                        color:
                                                                            borderColor,
                                                                        size:
                                                                            18),
                                                                    onPressed:
                                                                        () {
                                                                      searchController
                                                                          .clear();
                                                                      provider
                                                                          .setSearchQuery(
                                                                              '');
                                                                    },
                                                                  )
                                                                : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        width(context) * 0.01),
                                                GestureDetector(
                                                  onTap: () {
                                                    provider.setSearchQuery(
                                                      searchController.text
                                                          .toLowerCase(),
                                                    );
                                                  },
                                                  child: Container(
                                                    height: 45,
                                                    width: 45,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: primaryColor,
                                                    ),
                                                    child: Icon(
                                                        Icons.search_rounded,
                                                        size: 24,
                                                        color: whiteColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      const SizedBox(height: 20),
                                      StreamBuilder<Object>(
                                          stream:
                                              UserServices.userByStatusStream(
                                            'pending',
                                            provider.selectedTown,
                                            isTablet,
                                          ),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            } else {
                                              final pendingUsers =
                                                  snapshot.data! as List;
                                              if (pendingUsers.isEmpty) {
                                                return Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(height: 180),
                                                    Center(
                                                      child: Image.asset(
                                                        'assets/images/notFound.png',
                                                        width: 80,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      'userRegistrationScreen.noPendingUsersRightNow'
                                                          .tr(),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    )
                                                  ],
                                                );
                                              } else {
                                                return Wrap(
                                                  runSpacing: p,
                                                  children: List.generate(
                                                      pendingUsers.length,
                                                      (index) {
                                                    final AppUser data =
                                                        pendingUsers[index];
                                                    if (isTablet &&
                                                            data.house['name']
                                                                .contains(provider
                                                                    .searchQuery) ||
                                                        (!isTablet &&
                                                            (data.house['name']
                                                                    .contains(
                                                                        provider
                                                                            .searchQuery) ||
                                                                data.town[
                                                                        'name']
                                                                    .contains(
                                                                        provider
                                                                            .searchQuery)))) {
                                                      return Stack(
                                                        children: [
                                                          Container(
                                                            height: 90,
                                                            width:
                                                                width(context),
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          radius),
                                                              color: greyColor,
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(100),
                                                                          child:
                                                                              CachedNetworkImage(
                                                                            imageUrl:
                                                                                data.profileImageURL ?? '',
                                                                            placeholder: (context, url) =>
                                                                                const Center(child: CircularProgressIndicator()),
                                                                            errorWidget: (context, url, error) =>
                                                                                Image.asset('assets/avatar.png'),
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: width(context) *
                                                                            0.03,
                                                                      ),
                                                                      Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            '${data.firstName} ${data.lastName}',
                                                                            style:
                                                                                const TextStyle(fontWeight: FontWeight.bold),
                                                                          ),
                                                                          if (data.house !=
                                                                              null)
                                                                            Text(
                                                                              '${'userRegistrationScreen.houseColon'.tr()} ${data.house['name']}',
                                                                              style: const TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          Text(
                                                                            'userRegistrationScreen.townColon'.tr(),
                                                                            style:
                                                                                const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          townPipe(
                                                                              data),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      MouseRegion(
                                                                        cursor:
                                                                            SystemMouseCursors.click,
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              38,
                                                                          width:
                                                                              38,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              border: Border.all(
                                                                                color: borderColor,
                                                                              )),
                                                                          child: Center(
                                                                              child: Icon(
                                                                            Icons.close,
                                                                            color:
                                                                                borderColor,
                                                                            size:
                                                                                18,
                                                                          )),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: width(context) *
                                                                            0.02,
                                                                      ),
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(radius),
                                                                                  ),
                                                                                  title: Center(child: Text('userRegistrationScreen.alert'.tr())),
                                                                                  content: SizedBox(
                                                                                    width: isTablet ? 350 : width(context),
                                                                                    height: 135,
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.symmetric(horizontal: p),
                                                                                      child: Column(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          const SizedBox(
                                                                                            height: 5,
                                                                                          ),
                                                                                          Text(textAlign: TextAlign.center, 'userRegistrationScreen.areYouSureToRegisterThisUserForAguaMed'.tr()),
                                                                                          const SizedBox(
                                                                                            height: 8,
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: MouseRegion(
                                                                                                    cursor: SystemMouseCursors.click,
                                                                                                    child: Button(
                                                                                                        color: secondaryColor,
                                                                                                        height: isTablet ? 40 : 35,
                                                                                                        width: width(context),
                                                                                                        text: 'userRegistrationScreen.cancel'.tr(),
                                                                                                        fontSize: isTablet ? 12 : 10,
                                                                                                        onPressed: () {
                                                                                                          // updateRoleAndStatus(data['id'] , 'houseOwner');
                                                                                                          pop(context);
                                                                                                        }),
                                                                                                  ),
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  width: width(context) * 0.02,
                                                                                                ),
                                                                                                Expanded(
                                                                                                  child: MouseRegion(
                                                                                                    cursor: SystemMouseCursors.click,
                                                                                                    child: Button(
                                                                                                        color: secondaryColor,
                                                                                                        height: isTablet ? 40 : 35,
                                                                                                        width: width(context),
                                                                                                        text: 'userRegistrationScreen.accept'.tr(),
                                                                                                        fontSize: isTablet ? 12 : 10,
                                                                                                        onPressed: () {
                                                                                                          registration(data.uid, 'HouseOwner');
                                                                                                          pop(context);
                                                                                                        }),
                                                                                                  ),
                                                                                                )
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            height: p,
                                                                                          ),
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              MouseRegion(
                                                                                                cursor: SystemMouseCursors.click,
                                                                                                child: Button(
                                                                                                  textColor: blackColor,
                                                                                                  color: transparentColor,
                                                                                                  height: 30,
                                                                                                  width: width(context) * 0.1,
                                                                                                  text: 'userRegistrationScreen.close'.tr(),
                                                                                                  fontSize: isTablet ? 14 : 12,
                                                                                                  onPressed: () => Navigator.pop(context),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  contentPadding: EdgeInsets.zero,
                                                                                );
                                                                              });
                                                                        },
                                                                        child:
                                                                            MouseRegion(
                                                                          cursor:
                                                                              SystemMouseCursors.click,
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                38,
                                                                            width:
                                                                                38,
                                                                            decoration:
                                                                                BoxDecoration(shape: BoxShape.circle, color: secondaryColor),
                                                                            child: Center(
                                                                                child: Icon(
                                                                              Icons.check,
                                                                              color: whiteColor,
                                                                              size: 18,
                                                                            )),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            bottom: 6,
                                                            right: 8,
                                                            child: Text(
                                                              '${DateTime.now().toLocal().year}/'
                                                              '${DateTime.now().toLocal().month.toString().padLeft(2, '0')}'
                                                              '/${DateTime.now().toLocal().day.toString().padLeft(2, '0')}',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 10,
                                                                  color:
                                                                      borderColor),
                                                            ),
                                                          )
                                                        ],
                                                      );
                                                    } else {
                                                      return const SizedBox();
                                                    }
                                                  }),
                                                );
                                              }
                                            }
                                          })
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
