import 'package:agua_med/Components/bottomSheets/InspectorTownsFilterBottomSheet.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/providers/user_home_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Inspector/meter_reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../Components/Drawer.dart';

class InspectorHomeScreen extends StatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  State<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen> {
  var notification = NotificationClass();
  FirebaseFirestore instance = FirebaseFirestore.instance;
  var searchController = TextEditingController();
  bool showPendingOnly = false;

  @override
  void initState() {
    context
        .read<UserHomeProvider>()
        .setSelectedTown(context.read<UserProvider>().user?.town.first);
    notification.notificationListener();
    super.initState();
  }

  bool checkReading(item) {
    var lastReading = item.lastReading;
    if (lastReading == null || lastReading.isEmpty) {
      return false;
    }
    if (lastReading['date'] != null) {
      Timestamp timestamp = lastReading['date'];
      DateTime lastReadingDate = timestamp.toDate();
      DateTime now = DateTime.now();
      bool isInCurrentMonth = lastReadingDate.year == now.year &&
          lastReadingDate.month == now.month;
      return isInCurrentMonth
          ? lastReading['measurementStatus'] == 'completed'
          : false;
    }

    return false;
  }

  void showTownBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return InspectorTownsFilterBottomSheet(
          towns: context.read<UserProvider>().user?.town ?? [],
          onSelected: (val) {
            pop(context);
            context.read<UserHomeProvider>().setSelectedTown(val);
          },
        );
      },
    );
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<UserHomeProvider>().reset();
        }
      },
      child: GestureDetector(
        onTap: () => unFocus(context),
        child: Consumer<UserHomeProvider>(
          builder: (context, provider, child) {
            return Scaffold(
              appBar: isTablet
                  ? AppBar(
                      centerTitle: true,
                      // automaticallyImplyLeading: false,
                      title: Text(selectedTown['name']),
                      backgroundColor: primaryColor,
                      actions: [
                        IconButton(
                          icon:
                              Icon(Icons.home_work_rounded, color: whiteColor),
                          onPressed: () {
                            unFocus(context);
                            showTownBottomSheet();
                          },
                        ),
                      ],
                    )
                  : AppBar(
                      backgroundColor: primaryColor,
                      title: Text(selectedTown['name']),
                      actions: [
                        IconButton(
                          icon:
                              Icon(Icons.home_work_rounded, color: whiteColor),
                          onPressed: () {
                            unFocus(context);
                            showTownBottomSheet();
                          },
                        ),
                      ],
                    ),
              drawer: const CustomDrawer(),
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder(
                            stream: HouseServices.houseReadingStream(
                              provider.selectedTown['id'],
                            ),
                            builder: (context, snapshot) {
                              // print(snapshot.data);
                              List<dynamic> visibleItems =
                                  snapshot.data?.where((item) {
                                        bool hasReadings = checkReading(item);
                                        bool matchesSearch =
                                            provider.searchValue == null ||
                                                provider.searchValue == '' ||
                                                item.name
                                                    .toLowerCase()
                                                    .contains(provider
                                                        .searchValue!
                                                        .toLowerCase());
                                        bool matchesPendingFilter =
                                            !provider.showPendingOnly ||
                                                !hasReadings;
                                        return matchesSearch &&
                                            matchesPendingFilter;
                                      }).toList() ??
                                      [];

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: p),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: searchController,
                                      decoration: InputDecoration(
                                        hintText:
                                            'InspectorHomeScreen.searchByName'
                                                .tr(),
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: whiteColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                      onChanged: (value) =>
                                          provider.setSearchValue(value),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'InspectorHomeScreen.showPendingOnly'
                                              .tr(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Switch(
                                          value: provider.showPendingOnly,
                                          activeColor: primaryColor,
                                          inactiveTrackColor: darkGreyColor,
                                          onChanged: (value) {
                                            provider.setShoePendingOnly(value);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.data == null)
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 50),
                                            Icon(Icons.home_work_rounded,
                                                size: 50, color: primaryColor),
                                            SizedBox(height: p),
                                            Text(
                                              'InspectorHomeScreen.noHousesFound'
                                                  .tr(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                                'InspectorHomeScreen.switchToOtherTown'
                                                    .tr()),
                                            const SizedBox(height: 50),
                                          ],
                                        ),
                                      ),
                                    GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 8.0,
                                        mainAxisSpacing: 8.0,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: visibleItems.length,
                                      itemBuilder: (context, index) {
                                        dynamic item = visibleItems[index];
                                        bool hasReadings = checkReading(item);

                                        return buildGridItem(item, hasReadings);
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildGridItem(dynamic data, bool hasReadings) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MeterReadingScreen(data: data, hasReadings: hasReadings)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasReadings ? greenColor : redColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasReadings
                  ? 'InspectorHomeScreen.completed'.tr()
                  : 'InspectorHomeScreen.pending'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
