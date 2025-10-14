// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/_helpers/notification.dart';
import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/providers/user_home_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Inspector/meter_reading.dart';
import 'package:agua_med/views/Inspector/search_house_bill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    notification.notificationListener();
    context.read<UserHomeProvider>().setSelectedTown(
          context.read<UserProvider>().user!.town,
        );
    super.initState();
  }

  bool checkReading(House item) {
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
        child: Consumer<UserHomeProvider>(builder: (context, provider, child) {
          return Scaffold(
            appBar: isTablet
                ? null
                : AppBar(
                    backgroundColor: primaryColor,
                    title: const Text("Dashboard").tr(),
                  ),
            drawer: isTablet ? null : const CustomDrawer(),
            body: StreamBuilder(
                stream: HouseServices.houseReadingStream(
                  provider.selectedTown['id'],
                ),
                builder: (context, snapshot) {
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
                                        hintText:
                                            'HomeScreen.searchByTownName'.tr(),
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: whiteColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          provider.setSearchValue(value),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'HomeScreen.showPendingOnly',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ).tr(),
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
                                            const Text(
                                              'HomeScreen.noHouseFoundInThisTown',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ).tr(),
                                            const SizedBox(height: 50),
                                          ],
                                        ),
                                      ),
                                    Wrap(
                                      children: List.generate(
                                        snapshot.data?.length ?? 0,
                                        (index) {
                                          House item = snapshot.data![index];
                                          bool hasReadings = checkReading(item);
                                          if (provider.searchValue == null ||
                                              provider.searchValue == '') {
                                            if (item.id ==
                                                context
                                                    .read<UserProvider>()
                                                    .user!
                                                    .house['id']) {
                                              if (!provider.showPendingOnly ||
                                                  !hasReadings) {
                                                return buildHouseCard(
                                                  item,
                                                  hasReadings,
                                                );
                                              } else {
                                                return const SizedBox();
                                              }
                                            } else {
                                              return const SizedBox();
                                            }
                                          } else {
                                            if (item.name
                                                .toLowerCase()
                                                .contains(provider.searchValue!
                                                    .toLowerCase())) {
                                              if (!provider.showPendingOnly ||
                                                  !hasReadings) {
                                                return buildHouseCard(
                                                  item,
                                                  hasReadings,
                                                );
                                              } else {
                                                return const SizedBox();
                                              }
                                            } else {
                                              return const SizedBox();
                                            }
                                          }
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
                }),
          );
        }),
      ),
    );
  }

  Widget buildHouseCard(House data, bool hasReadings) {
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
                if (data.lastReading != null) ...[
                  _buildConsumptionRow(data),
                  const SizedBox(height: 15),
                  buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'HomeScreen.date',
                    value: data.lastReading?['date'] == null
                        ? 'No Available'
                        : dateFromTimestamp(data.lastReading!['date']),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.speed,
                    label: 'HomeScreen.reading',
                    value: data.lastReading!['reading'].toStringAsFixed(2),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.bolt,
                    label: 'HomeScreen.calcConsumption',
                    value: data.lastReading!['units'].toStringAsFixed(2),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.history_toggle_off,
                    label: 'HomeScreen.lastConsumption',
                    value:
                        data.lastReading!['previousUnits'].toStringAsFixed(2),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'HomeScreen.consumptionDays',
                    value: data.lastReading!['consumptionDays'].toString(),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'HomeScreen.amount',
                    value: '\$${data.lastReading!['amount']}',
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.water_drop,
                    label: 'SearchHouseScreen.consumption',
                    value: data.cohabitants == null || data.houseType == null
                        ? ''
                        : consumptionLevel(
                            data.houseType!,
                            data.cohabitants!,
                            double.parse(
                              data.lastReading!['units'].toStringAsFixed(2),
                            ),
                          ),
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

  String consumptionLevel(
      String houseType, int cohabitants, double consumption) {
    if (houseType == "Living") {
      switch (cohabitants) {
        case 2:
          if (consumption < 22) {
            return "Low";
          } else if (consumption <= 39)
            return "Medium";
          else
            return "High";
        case 3:
          if (consumption < 27) {
            return "Low";
          } else if (consumption <= 45)
            return "Medium";
          else
            return "High";
        case 4:
          if (consumption < 33) {
            return "Low";
          } else if (consumption <= 63)
            return "Medium";
          else
            return "High";
        case 5:
          if (consumption < 39) {
            return "Low";
          } else if (consumption <= 84)
            return "Medium";
          else
            return "High";
        case 6:
          if (consumption < 45) {
            return "Low";
          } else if (consumption <= 108)
            return "Medium";
          else
            return "High";
        default:
          return "Unknown"; // or handle invalid cohabitants number
      }
    } else if (houseType == "Weekend") {
      switch (cohabitants) {
        case 2:
          if (consumption < 5.84) {
            return "Low";
          } else if (consumption <= 10.4)
            return "Medium";
          else
            return "High";
        case 3:
          if (consumption < 7.2) {
            return "Low";
          } else if (consumption <= 12)
            return "Medium";
          else
            return "High";
        case 4:
          if (consumption < 8.8) {
            return "Low";
          } else if (consumption <= 16.8)
            return "Medium";
          else
            return "High";
        case 5:
          if (consumption < 10.4) {
            return "Low";
          } else if (consumption <= 22.4)
            return "Medium";
          else
            return "High";
        case 6:
          if (consumption < 12) {
            return "Low";
          } else if (consumption <= 28.8)
            return "Medium";
          else
            return "High";
        default:
          return "Unknown"; // or handle invalid cohabitants number
      }
    } else {
      return "Unknown"; // or handle invalid house type
    }
  }

  Widget _buildCardHeader(House data, bool hasReadings) {
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
            data.name,
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

  Widget _buildConsumptionRow(House data) {
    var consumption = (double.parse(data.lastReading!['reading'].toString()) -
            double.parse(data.lastReading!['previousReading'].toString()))
        .toStringAsFixed(2);
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

  Widget _buildCardFooter(House data, bool hasReadings) {
    return Padding(
      padding: EdgeInsets.all(p),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeterReadingScreen(
                      data: data,
                      hasReadings: hasReadings,
                    ),
                  ),
                );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchHouseScreen(),
                  ),
                );
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

  Widget buildInfoRow(
      {required IconData icon, required String label, required String value}) {
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
