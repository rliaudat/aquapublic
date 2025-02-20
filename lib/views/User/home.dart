import 'dart:async';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Inspector/meter_reading.dart';
import 'package:agua_med/views/Inspector/search_house_bill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseFirestore instance = FirebaseFirestore.instance;
  var notification = NotificationClass();
  var searchController = TextEditingController();
  String searchValue = "";
  bool showPendingOnly = false;

  List allData = [];
  List filteredData = [];

  @override
  void initState() {
    notification.notificationListener();
    Timer(const Duration(milliseconds: 10), () {
      loadData();
    });
    super.initState();
  }

  void loadData() {
    selectedTown = userSD['town'];
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

  showPending(pending) {
    unFocus(context);
    pending ? filteredData = allData.where((item) => !checkReading(item)).toList() : filteredData = allData;
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
                title: const Text("Dashboard").tr(),
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
                            title: const Text('Dashboard').tr(),
                            backgroundColor: primaryColor,
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
                              hintText: 'HomeScreen.searchByTownName'.tr(),
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
                              const Text(
                                'HomeScreen.showPendingOnly',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ).tr(),
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
                          if (filteredData.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 50),
                                  Icon(Icons.home_work_rounded, size: 50, color: primaryColor),
                                  SizedBox(height: p),
                                  const Text(
                                    'HomeScreen.noHouseFoundInThisTown',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ).tr(),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          Wrap(
                            children: List.generate(
                              filteredData.length,
                              (index) {
                                dynamic item = filteredData[index];
                                bool hasReadings = checkReading(item);
                                return buildHouseCard(item, hasReadings);
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
        ),
      ),
    );
  }

  Widget buildHouseCard(dynamic data, bool hasReadings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(data, hasReadings),
          Padding(
            padding: EdgeInsets.all(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (data['lastReading'] != null) ...[
                  _buildConsumptionRow(data),
                  const SizedBox(height: 15),
                  buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'HomeScreen.date',
                    value: dateFromTimestamp(data['lastReading']['date']),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.speed,
                    label: 'HomeScreen.reading',
                    value: data['lastReading']['reading'],
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.bolt,
                    label: 'HomeScreen.calcConsumption',
                    value: data['lastReading']['units'].toString(),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.history_toggle_off,
                    label: 'HomeScreen.lastConsumption',
                    value: data['lastReading']['previousUnit'].toString(),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'HomeScreen.consumptionDays',
                    value: data['lastReading']['consumptionDays'].toString(),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'HomeScreen.amount',
                    value: '\$${data['lastReading']['amount']}',
                  ),
                ],
              ],
            ),
          ),
          _buildCardFooter(data, hasReadings),
        ],
      ),
    );
  }

  Widget _buildCardHeader(dynamic data, bool hasReadings) {
    return Container(
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: hasReadings ? greenColor : redColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            hasReadings ? 'HomeScreen.captured' : 'HomeScreen.pending',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).tr(),
        ],
      ),
    );
  }

  Widget _buildConsumptionRow(data) {
    var consumption = (double.parse(data['lastReading']['reading'].toString()) - double.parse(data['lastReading']['previousReading'].toString())).toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed, color: primaryColor, size: 30),
        const SizedBox(width: 8),
        Text(
          '$consumption m³',
          style: TextStyle(
            color: blueColor,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(dynamic data, bool hasReadings) {
    return Padding(
      padding: EdgeInsets.all(p),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MeterReadingScreen(data: data, hasReadings: hasReadings)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                fixedSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.camera_alt, color: whiteColor),
              label: Text(
                'HomeScreen.newReading',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchHouseScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                fixedSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.bar_chart, color: whiteColor),
              label: Text(
                'HomeScreen.historicalData',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: darkGreyColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: darkGreyColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ).tr(),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
