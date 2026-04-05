import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_services/admin_Services.dart';
import 'package:agua_med/_services/user_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:agua_med/providers/all_user_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../Components/bottomSheets/user_filter.dart';
import '../../../loading.dart';
import 'create_user.dart';
import 'owner_details.dart';

class AllUsersScreen extends StatefulWidget {
  final String role;
  final String header;
  const AllUsersScreen({super.key, required this.role, required this.header});
  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String img = '';
  AdminService adminService = AdminService();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    if (widget.role == 'HouseOwner') img = 'assets/images/allUsers.png';
    if (widget.role == 'Inspector') img = 'assets/images/inspector.png';
    if (widget.role == 'Manager') img = 'assets/images/management.png';
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  filterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const UserFilterBottomSheet();
      },
    );
  }

  handleStatus(String value, String userId) {
    if (value == 'delete') {
      adminService.deleteUser(userId);
      showToast(context, msg: 'AllUsersScreen.delete'.tr());
    } else if (value == 'block') {
      adminService.blockUser(userId);
      showToast(context, msg: 'AllUsersScreen.block'.tr());
    } else if (value == 'unblock') {
      adminService.unblockUser(userId);
      showToast(context, msg: 'AllUsersScreen.unblock'.tr());
    }
    if (mounted) setState(() {});
  }

  Widget townPipe(data) {
    List towns = [];
    var town = data.town ?? {"name": "No Town"};
    if (widget.role == 'Inspector') {
      towns.insertAll(0, town);
    } else {
      towns.add(town);
    }
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

  bool _matchesTown(dynamic userTown, dynamic accessibleTowns) {
    final scopedTownIds = _extractTownIds(accessibleTowns);
    if (scopedTownIds.isEmpty) return false;

    if (userTown is Map) {
      return scopedTownIds.contains(userTown['id']);
    }

    if (userTown is List) {
      return userTown.any(
        (town) => town is Map && scopedTownIds.contains(town['id']),
      );
    }

    return false;
  }

  Set<String> _extractTownIds(dynamic rawTown) {
    if (rawTown is Map && rawTown['id'] != null) {
      return {rawTown['id'].toString()};
    }
    if (rawTown is List) {
      return rawTown
          .whereType<Map>()
          .map((town) => town['id'])
          .whereType<Object>()
          .map((id) => id.toString())
          .toSet();
    }
    return <String>{};
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Consumer<AllUserProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar:
                isTablet ? null : CustomAppBar(title: 'All ${widget.header}'),
            floatingActionButton: isTablet
                ? Container()
                : FloatingActionButton(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.add, color: whiteColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateOwnerScreen(
                            role: widget.role,
                            header: widget.header,
                          ),
                        ),
                      );
                    },
                  ),
            body: StreamBuilder(
              stream: UserServices.userByRoleStream(widget.role),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isTablet ? const CustomDrawer() : Container(),
                      const Expanded(
                          child: Center(child: CircularProgressIndicator())),
                    ],
                  );
                }
                final currentUser = context.read<UserProvider>().user;
                final accessibleTowns = currentUser?.town;
                final users = List<AppUser>.from(snapshot.data! as List);
                final scopedUsers = currentUser != null &&
                        currentUser.role != 'Admin'
                    ? users
                        .where(
                          (user) => _matchesTown(user.town, accessibleTowns),
                        )
                        .toList()
                    : users;

                if (scopedUsers.isEmpty) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isTablet ? const CustomDrawer() : Container(),
                      Expanded(
                        child: Column(
                          children: [
                            isTablet
                                ? CustomAppBar(
                                    title: 'All ${widget.header}',
                                    showButton: false,
                                    showAction: false)
                                : Container(),
                            const SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: p),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 45,
                                          child: TextField(
                                            controller: searchController,
                                            onChanged: (value) {
                                              provider.setSearchQuery(
                                                value.toLowerCase(),
                                              );
                                            },
                                            decoration: InputDecoration(
                                              hintText:
                                                  'AllUsersScreen.searchByEmailNameTownNameHouseName'
                                                      .tr(),
                                              prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                  color: borderColor),
                                              suffixIcon: searchController
                                                      .text.isNotEmpty
                                                  ? IconButton(
                                                      onPressed: () {
                                                        provider.setSearchQuery(
                                                          "",
                                                        );
                                                      },
                                                      icon: Icon(Icons.clear,
                                                          color: borderColor,
                                                          size: 18))
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          provider.setSearchQuery(
                                            searchController.text.toLowerCase(),
                                          );
                                        },
                                        child: Container(
                                          height: 45,
                                          width: 45,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor,
                                          ),
                                          child: Icon(Icons.search_rounded,
                                              size: 24, color: whiteColor),
                                        ),
                                      ),
                                      SizedBox(width: width(context) * 0.01),
                                      if (isTablet)
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) =>
                                              provider.setAddHover(true),
                                          onExit: (_) =>
                                              provider.setAddHover(false),
                                          child: Button(
                                            color: provider.addHover
                                                ? primaryColor
                                                : secondaryColor,
                                            borderRadius: radius,
                                            height: 45,
                                            width: width(context) / 9,
                                            text: 'AllUsersScreen.addNew'.tr(),
                                            fontSize: width(context) * 0.0115,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreateOwnerScreen(
                                                    role: widget.role,
                                                    header: widget.header,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 120),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(img,
                                          width: 60, color: primaryColor),
                                      SizedBox(height: p),
                                      Text(
                                        'AllUsersScreen.noUsersFound'.tr(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'AllUsersScreen.clickOnButtonToAddUser'
                                            .tr(),
                                        style: TextStyle(color: textColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                dynamic filteredOwners;
                if (provider.searchQuery.isEmpty) {
                  filteredOwners = scopedUsers;
                } else {
                  if (widget.role == 'HouseOwner') {
                    final searchFields = [
                      'email',
                      'firstName',
                      'lastName',
                      'house.name',
                      'town.name'
                    ];
                    filteredOwners = scopedUsers.where((doc) {
                      final docData = doc.toMap();
                      return searchFields.any((field) {
                        var temp = field.split('.');
                        if (temp.length > 1) {
                          final fieldValue =
                              (docData[temp[0]][temp[1]] as String?)
                                      ?.toLowerCase() ??
                                  '';
                          return fieldValue
                              .contains(provider.searchQuery.toLowerCase());
                        } else {
                          final fieldValue =
                              (docData[field] as String?)?.toLowerCase() ?? '';
                          return fieldValue
                              .contains(provider.searchQuery.toLowerCase());
                        }
                      });
                    }).toList();
                  }
                  if (widget.role == 'Inspector' || widget.role == 'Manager') {
                    final searchFields = [
                      'email',
                      'firstName',
                      'lastName',
                      'town.name'
                    ];

                    filteredOwners = scopedUsers.where((doc) {
                      final docData = doc.toMap();
                      return searchFields.any((field) {
                        var temp = field.split('.');
                        if (temp.length > 1) {
                          if (temp[0] == 'town' && docData[temp[0]] is List) {
                            return (docData[temp[0]] as List).any((town) {
                              final fieldValue =
                                  (town[temp[1]] as String?)?.toLowerCase() ??
                                      '';
                              return fieldValue
                                  .contains(provider.searchQuery.toLowerCase());
                            });
                          } else {
                            final fieldValue =
                                (docData[temp[0]][temp[1]] as String?)
                                        ?.toLowerCase() ??
                                    '';
                            return fieldValue
                                .contains(provider.searchQuery.toLowerCase());
                          }
                        } else {
                          final fieldValue =
                              (docData[field] as String?)?.toLowerCase() ?? '';
                          return fieldValue
                              .contains(provider.searchQuery.toLowerCase());
                        }
                      });
                    }).toList();
                  }
                }
                return Row(
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
                                ? CustomAppBar(
                                    title: 'All ${widget.header}',
                                    showButton: false,
                                    showAction: false)
                                : Container(),
                            const SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: p),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 45,
                                          child: TextField(
                                            controller: searchController,
                                            onChanged: (value) {
                                              provider.setSearchQuery(
                                                  value.toLowerCase());
                                            },
                                            decoration: InputDecoration(
                                              hintText:
                                                  'AllUsersScreen.searchByEmailNameTownNameHouseName'
                                                      .tr(),
                                              prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                  color: borderColor),
                                              suffixIcon: searchController
                                                      .text.isNotEmpty
                                                  ? IconButton(
                                                      onPressed: () {
                                                        searchController
                                                            .clear();
                                                        provider
                                                            .setSearchQuery("");
                                                      },
                                                      icon: Icon(Icons.clear,
                                                          color: borderColor,
                                                          size: 18))
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          provider.setSearchQuery(
                                              searchController.text
                                                  .toLowerCase());
                                        },
                                        child: Container(
                                          height: 45,
                                          width: 45,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor,
                                          ),
                                          child: Icon(Icons.search_rounded,
                                              size: 24, color: whiteColor),
                                        ),
                                      ),
                                      SizedBox(width: width(context) * 0.01),
                                      if (isTablet)
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) =>
                                              provider.setAddHover(true),
                                          onExit: (_) =>
                                              provider.setAddHover(false),
                                          child: Button(
                                            color: provider.addHover
                                                ? primaryColor
                                                : secondaryColor,
                                            borderRadius: radius,
                                            height: 45,
                                            width: width(context) / 9,
                                            text: 'AllUsersScreen.addNew'.tr(),
                                            fontSize: width(context) * 0.0115,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreateOwnerScreen(
                                                    role: widget.role,
                                                    header: widget.header,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  filteredOwners.isEmpty
                                      ? Column(
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
                                            )),
                                            const SizedBox(height: 10),
                                            Text(
                                              'AllUsersScreen.noSearchResultsFound'
                                                  .tr(),
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        )
                                      : Wrap(
                                          runSpacing: 10,
                                          children: List.generate(
                                            filteredOwners.length,
                                            (index) {
                                              final data =
                                                  filteredOwners[index];
                                              return Stack(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              OwnerDetailsScreen(
                                                            data: data,
                                                            header:
                                                                widget.header,
                                                            role: widget.role,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .click,
                                                      child: Container(
                                                        height: 90,
                                                        width: double.infinity,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color: greyColor,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  SizedBox(
                                                                    height: 50,
                                                                    width: 50,
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              100),
                                                                      child:
                                                                          CachedNetworkImage(
                                                                        imageUrl:
                                                                            data.profileImageURL ??
                                                                                "",
                                                                        placeholder:
                                                                            (context, url) =>
                                                                                const Center(child: CircularProgressIndicator()),
                                                                        errorWidget: (context,
                                                                                url,
                                                                                error) =>
                                                                            Image.asset('assets/avatar.png'),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          15),
                                                                  Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        '${data.firstName} ${data.lastName}',
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      Text(
                                                                        '${data.email}',
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12),
                                                                      ),
                                                                      if (data.house !=
                                                                          null)
                                                                        Text(
                                                                          '${'AllUsersScreen.house'.tr()}: ${data.house['name']}',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      Wrap(
                                                                        children: [
                                                                          Text(
                                                                            '${'AllUsersScreen.town'.tr()}:',
                                                                            style:
                                                                                const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 8),
                                                                          townPipe(
                                                                              data),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                              PopupMenuButton(
                                                                icon: Icon(
                                                                    Icons
                                                                        .more_vert,
                                                                    color:
                                                                        borderColor),
                                                                onSelected: (value) =>
                                                                    handleStatus(
                                                                        value,
                                                                        data[
                                                                            'id']),
                                                                itemBuilder:
                                                                    (context) {
                                                                  return [
                                                                    PopupMenuItem(
                                                                      value:
                                                                          'delete',
                                                                      child: Text(
                                                                          'AllUsersScreen.delete'
                                                                              .tr()),
                                                                    ),
                                                                    PopupMenuItem(
                                                                      value:
                                                                          'block',
                                                                      child: Text(
                                                                          'AllUsersScreen.block'
                                                                              .tr()),
                                                                    ),
                                                                    PopupMenuItem(
                                                                      value:
                                                                          'unblock',
                                                                      child: Text(
                                                                          'AllUsersScreen.unblock'
                                                                              .tr()),
                                                                    ),
                                                                  ];
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 8,
                                                    bottom: 6,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          height: 10,
                                                          width: 10,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: data.status ==
                                                                    'blocked'
                                                                ? redColor
                                                                : greenColor,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            width: isTablet
                                                                ? width(context) *
                                                                    0.01
                                                                : width(context) *
                                                                    0.01),
                                                        Text(
                                                          data.status ==
                                                                  'blocked'
                                                              ? 'AllUsersScreen.blocked'
                                                                  .tr()
                                                              : 'AllUsersScreen.active'
                                                                  .tr(),
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
