import 'package:agua_med/Components/bottomSheets/InspectorTownsFilterBottomSheet.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Inspector/meter_reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  List allTowns = [];
  List allData = [];
  List filteredData = [];

  @override
  void initState() {
    notification.notificationListener();
    fetchTowns();
    super.initState();
  }

  fetchTowns() {
    allTowns = userSD['town'];
    if (allTowns.isNotEmpty) {
      var obj = {
        'name': allTowns[0]['name'],
        'id': allTowns[0]['id'],
      };
      selectedTown = obj;
      if (mounted) setState(() {});
      loadData();
    }
  }

  void loadData() {
    showPendingOnly = false;
    if (mounted) setState(() {});
    instance.collection('towns').doc(selectedTown['id']).collection('houses').where('isDelete', isEqualTo: false).orderBy('createdAt').snapshots().listen((housesSnapshot) {
      List<Map<String, dynamic>> tempAllData = [];

      for (var houseDoc in housesSnapshot.docs) {
        Map<String, dynamic> houseData = houseDoc.data();
        houseData['id'] = houseDoc.id;
        houseData['lastReading'] = null;

        instance.collection('towns').doc(selectedTown['id']).collection('houses').doc(houseDoc.id).collection('reading').orderBy('date', descending: true).limit(1).snapshots().listen((readingsSnapshot) {
          if (readingsSnapshot.docs.isNotEmpty) {
            houseData['lastReading'] = {'id': readingsSnapshot.docs.first.id, ...readingsSnapshot.docs.first.data()};
          } else {
            houseData['lastReading'] = null;
          }
          tempAllData = tempAllData.where((item) => item['id'] != houseDoc.id).toList();
          tempAllData.add(houseData);
          allData = tempAllData;
          filteredData = allData;
          if (mounted) setState(() {});
        });
      }
    });
  }

  bool checkReading(item) {
    var lastReading = item['lastReading'];
    if (lastReading == null || lastReading.isEmpty) {
      return false;
    }
    if (lastReading['date'] != null) {
      Timestamp timestamp = lastReading['date'];
      DateTime lastReadingDate = timestamp.toDate();
      DateTime now = DateTime.now();
      bool isInCurrentMonth = lastReadingDate.year == now.year && lastReadingDate.month == now.month;
      return isInCurrentMonth;
    }

    return false;
  }

  void searchHouse(String query) {
    if (query.isEmpty) {
      filteredData = List.from(allData);
    } else {
      filteredData = allData.where((data) => data['name'].toLowerCase().contains(query.toLowerCase())).toList();
    }
    if (mounted) setState(() {});
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
          towns: allTowns,
          onSelected: (val) {
            pop(context);
            selectedTown = val;
            loadData();
          },
        );
      },
    );
  }

  showPending(pending) {
    unFocus(context);
    pending ? filteredData = allData.where((item) => !checkReading(item)).toList() : filteredData = allData;
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
                title: Text(selectedTown['name']),
                actions: [
                  IconButton(
                    icon: Icon(Icons.home_work_rounded, color: whiteColor),
                    onPressed: () {
                      unFocus(context);
                      showTownBottomSheet();
                    },
                  ),
                ],
              ),
        drawer: isTablet ? null : const CustomDrawer(),
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
                            title: Text(selectedTown['name']),
                            backgroundColor: primaryColor,
                            actions: [
                              IconButton(
                                icon: Icon(Icons.home_work_rounded, color: whiteColor),
                                onPressed: () {
                                  unFocus(context);
                                  showTownBottomSheet();
                                },
                              ),
                            ],
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'InspectorHomeScreen.searchByName'.tr(),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: whiteColor,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (value) => searchHouse(value),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'InspectorHomeScreen.showPendingOnly'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Switch(
                                value: showPendingOnly,
                                activeColor: primaryColor,
                                inactiveTrackColor: darkGreyColor,
                                onChanged: (value) {
                                  showPendingOnly = value;
                                  showPending(showPendingOnly);
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          filteredData.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 50),
                                      Icon(Icons.home_work_rounded, size: 50, color: primaryColor),
                                      SizedBox(height: p),
                                      Text(
                                        'InspectorHomeScreen.noHousesFound'.tr(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text('InspectorHomeScreen.switchToOtherTown'.tr()),
                                      const SizedBox(height: 50),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: filteredData.length,
                                  itemBuilder: (context, index) {
                                    dynamic item = filteredData[index];
                                    bool hasReadings = checkReading(item);
                                    return buildGridItem(item, hasReadings);
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

  Widget buildGridItem(dynamic data, bool hasReadings) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MeterReadingScreen(data: data, hasReadings: hasReadings)));
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
              data['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasReadings ? 'InspectorHomeScreen.completed'.tr() : 'InspectorHomeScreen.pending'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
