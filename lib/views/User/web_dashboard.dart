import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';

class UserWebDashboardPage extends StatefulWidget {
  const UserWebDashboardPage({super.key});

  @override
  _UserWebDashboardPageState createState() => _UserWebDashboardPageState();
}

class _UserWebDashboardPageState extends State<UserWebDashboardPage> {
  List<String> townIdsList = [];
  List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  List<String> years = List.generate(
      DateTime.now().year - 2019, (index) => (2020 + index).toString());

  String? selectedTownId;
  String? selectedMonth;
  String? selectedYear;
  String? searchQuery = '';
  String? selectedHouseType;
  String? selectedConsumption;
  String? selectedMeasurementStatus;
  int currentPage = 1;
  int rowsPerPage = 10;

  bool isLoading = false;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> tableData = List.generate(5, (index) {
    return {
      "House ID": "H-${index + 1}",
      "Month": "February",
      "Water Meter ID": "M-${index + 1}",
      "Previous Reading": "${index * 10} m³",
      "Previous Reading Date": "2025-01-${index + 1}",
      "Reading": "${(index + 1) * 10} m³",
      "Reading Date": "2025-02-${index + 1}",
      "Days of Consumption": "30",
      "Calculated Consumption": "${5 * (index + 1)} m³",
      "House Type": "House",
      "Consumption Level": "normal",
      "Billing Status": index % 2 == 0 ? "open" : "closed",
      "Measurement Status": "pending",
      "View Image":
          'https://plus.unsplash.com/premium_photo-1664474619075-644dd191935f?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8aW1hZ2V8ZW58MHx8MHx8fDA%3D',
    };
  });

  List<Map<String, dynamic>> rowData = List.generate(5, (index) {
    return {
      "House ID": "H-${index + 1}",
      "Month": "February",
      "Water Meter ID": "M-${index + 1}",
      "Previous Reading": "${index * 10} m³",
      "Previous Reading Date": "2025-01-${index + 1}",
      "Reading": "${(index + 1) * 10} m³",
      "Reading Date": "2025-02-${index + 1}",
      "Days of Consumption": "30",
      "Calculated Consumption": "${5 * (index + 1)} m³",
      "House Type": "House",
      "Consumption Level": "normal",
      "Billing Status": index % 2 == 0 ? "open" : "closed",
      "Measurement Status": "pending",
      "View Image":
          'https://plus.unsplash.com/premium_photo-1664474619075-644dd191935f?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8aW1hZ2V8ZW58MHx8MHx8fDA%3D',
    };
  });

  @override
  void initState() {
    super.initState();
    selectedTownId = 'N7YwK26D9gtSssAwLfkE';
    selectedMonth = months[DateTime.now().month - 1];
    selectedYear = DateTime.now().year.toString();
    loadTowns();
    loadData();
  }

  loadTowns() {
    isLoading = true;
    if (mounted) setState(() {});
    firestore.collection('towns').snapshots().listen((querySnapshot) async {
      final towns = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.id;
        return data;
      }).toList());
      townIdsList = towns;
      if (mounted) setState(() {});
    }).onError((e) {
      debugPrint('Error loading data: $e');
    });
  }

  bool checkReading(item) {
    isLoading = true;
    if (mounted) setState(() {});
    var lastReading = item['lastReading'];
    if (lastReading == null || lastReading.isEmpty) {
      return false;
    }
    if (lastReading['date'] != null) {
      Timestamp timestamp = lastReading['date'];
      DateTime lastReadingDate = timestamp.toDate();
      DateTime now = DateTime.now();
      bool isInCurrentMonth = lastReadingDate.year == now.year &&
          lastReadingDate.month == now.month;
      return isInCurrentMonth;
    }

    return false;
  }

  void loadData() {
    firestore
        .collection('towns')
        .doc(selectedTownId)
        .collection('houses')
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .listen((housesSnapshot) {
      List<Map<String, dynamic>> tempAllData = [];
      List<Map<String, dynamic>> tempTableData = [];

      for (var houseDoc in housesSnapshot.docs) {
        Map<String, dynamic> houseData = houseDoc.data();
        houseData['id'] = houseDoc.id;
        houseData['lastReading'] = null;

        firestore
            .collection('towns')
            .doc(selectedTownId)
            .collection('houses')
            .doc(houseDoc.id)
            .collection('reading')
            .orderBy('date', descending: true)
            .limit(1)
            .snapshots()
            .listen((readingsSnapshot) {
          if (readingsSnapshot.docs.isNotEmpty) {
            houseData['lastReading'] = {
              'id': readingsSnapshot.docs.first.id,
              ...readingsSnapshot.docs.first.data()
            };
          } else {
            houseData['lastReading'] = null;
          }
          tempAllData =
              tempAllData.where((item) => item['id'] != houseDoc.id).toList();
          tempAllData.add(houseData);
          if (houseData['lastReading']?['date'] == null
              ? false
              : ((months[DateTime.fromMicrosecondsSinceEpoch(
                            houseData['lastReading']?['date']
                                .microsecondsSinceEpoch,
                          ).month -
                          1] ==
                      selectedMonth) &&
                  (DateTime.fromMicrosecondsSinceEpoch(
                        houseData['lastReading']?['date']
                            .microsecondsSinceEpoch,
                      ).year.toString() ==
                      selectedYear))) {
            tempTableData.add({
              "House ID": houseDoc.id,
              "Month": months[DateTime.fromMicrosecondsSinceEpoch(
                          (houseData['lastReading']?['date'] ?? Timestamp.now())
                              .microsecondsSinceEpoch)
                      .month -
                  1],
              "Water Meter ID": "M-1",
              "Previous Reading":
                  "${houseData['lastReading']?['previousReading'] ?? 0} m³",
              "Previous Reading Date": "2025-01-20",
              "Reading": "${houseData['lastReading']?['reading'] ?? 0} m³",
              "Reading Date": houseData['lastReading']?['date'] == null
                  ? ''
                  : DateFormat("yyyy-MM-dd").format(
                      DateTime.fromMicrosecondsSinceEpoch(
                        houseData['lastReading']?['date']
                            .microsecondsSinceEpoch,
                      ),
                    ),
              "Days of Consumption":
                  (houseData['lastReading']?['consumptionDays'] ?? 0)
                      .toString(),
              "Calculated Consumption":
                  "${int.parse((houseData['lastReading']?['reading'] ?? 0).toString()) - int.parse((houseData['lastReading']?['previousReading'] ?? 0).toString())} m³",
              "House Type": "House",
              "Consumption Level": "normal",
              "Billing Status": "closed",
              "Measurement Status":
                  checkReading(houseData) ? "completed" : "pending",
              "View Image": houseData['lastReading']?['consumptionDays'],
            });
          } else {
            tempTableData.add({
              "House ID": houseDoc.id,
              // "Month": months[DateTime.fromMicrosecondsSinceEpoch(
              //             Timestamp.now().microsecondsSinceEpoch)
              //         .month -
              //     1],
              "Month": selectedMonth,
              "Water Meter ID": "M-1",
              "Previous Reading":
                  "${houseData['lastReading']?['previousReading'] ?? 0} m³",
              "Previous Reading Date": "2025-01-20",
              "Reading": "",
              "Reading Date": '',
              "Days of Consumption": '',
              "Calculated Consumption": '',
              "House Type": "House",
              "Consumption Level": "normal",
              "Billing Status": "closed",
              "Measurement Status": "pending",
              "View Image": null,
            });
          }
          tableData = tempTableData;
          updateRowRecords();
          isLoading = false;
          if (mounted) setState(() {});
        });
      }
    });
  }

  void updateRowRecords() {
    rowData = tableData.sublist(
        ((currentPage - 1) * rowsPerPage),
        ((tableData.length - ((currentPage - 1) * rowsPerPage)) < rowsPerPage
            ? tableData.length
            : ((currentPage - 1) * rowsPerPage) + rowsPerPage));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: primaryColor,
      //   title: Text(
      //     "Readings",
      //     style: TextStyle(
      //       color: whiteColor,
      //       fontSize: 15,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // ),
      body: Row(
        children: [
          isDesktop ? const CustomDrawer() : Container(),
          if (!isLoading)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'Town ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items: townIdsList.map((String townID) {
                                return DropdownMenuItem(
                                  value: townID,
                                  child: Text(
                                    townID,
                                  ),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return townIdsList.map((String townID) {
                                  return SizedBox(
                                    width: 120, // Adjust width as needed
                                    child: Text(
                                      townID,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  );
                                }).toList();
                              },
                              onChanged: (value) {
                                loadData();
                                setState(() {
                                  selectedTownId = value as String;
                                });
                              },
                              value: selectedTownId,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'Month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items: months.map((String month) {
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                              onChanged: (value) {
                                loadData();
                                setState(() {
                                  selectedMonth = value as String;
                                });
                              },
                              value: selectedMonth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'Year',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items: years.map((String year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                );
                              }).toList(),
                              onChanged: (value) {
                                loadData();
                                setState(() {
                                  selectedYear = value as String;
                                });
                              },
                              value: selectedYear,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'House Type',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items:
                                  ["Living", "Weekend", "All"].map((String houseType) {
                                return DropdownMenuItem(
                                  value: houseType,
                                  child: Text(houseType),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedHouseType = value as String;
                                });
                              },
                              value: selectedHouseType,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'Consumption Filter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items: ["Normal", "Medium", "High","All"]
                                  .map((String consumptionFilter) {
                                return DropdownMenuItem(
                                  value: consumptionFilter,
                                  child: Text(consumptionFilter),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedConsumption = value as String;
                                });
                              },
                              value: selectedConsumption,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  'Measurement Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              items: ["Pending", "Complete", "All"]
                                  .map((String measurementStatus) {
                                return DropdownMenuItem(
                                  value: measurementStatus,
                                  child: Text(measurementStatus),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMeasurementStatus = value as String;
                                });
                              },
                              value: selectedMeasurementStatus,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.download,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Search by House ID",
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 600),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Rows per page:',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 65,
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(radius),
                                ),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                  ),
                                  items: ["10", "15", "20"]
                                      .map((String houseType) {
                                    return DropdownMenuItem(
                                      value: houseType,
                                      child: Text(
                                        houseType,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      rowsPerPage = int.parse(value as String);
                                    });
                                    updateRowRecords();
                                  },
                                  value: rowsPerPage.toString(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '${((currentPage - 1) * rowsPerPage) + 1} - ${((tableData.length - ((currentPage - 1) * rowsPerPage)) < rowsPerPage ? tableData.length : ((currentPage - 1) * rowsPerPage) + rowsPerPage)} of ${tableData.length}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (currentPage != 1) {
                                  setState(() {
                                    currentPage--;
                                  });
                                  updateRowRecords();
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 18,
                                color: currentPage != 1
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (currentPage <
                                    (tableData.length / rowsPerPage)) {
                                  setState(() {
                                    currentPage++;
                                  });
                                  updateRowRecords();
                                }
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: currentPage <
                                        (tableData.length / rowsPerPage)
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(primaryColor),
                            columnSpacing: 10,
                            columns: tableData.first.keys
                                .map(
                                  (key) => DataColumn(
                                    label: Center(
                                      child: SizedBox(
                                        width: 140,
                                        child: Text(
                                          key,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: whiteColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            rows: rowData
                                .where((row) =>
                                    row["House ID"].contains(searchQuery))
                                .map((row) => DataRow(
                                      cells: row.entries
                                          .map(
                                            (entry) => DataCell(SizedBox(
                                              width: 140,
                                              child: entry.key == 'View Image'
                                                  ? entry.value == null
                                                      ? const Text('')
                                                      : IconButton(
                                                          onPressed: () async {
                                                            !await launchUrl(
                                                              Uri.parse(
                                                                entry.value
                                                                    .toString(),
                                                              ),
                                                            );
                                                          },
                                                          icon: const Icon(
                                                              Icons.image),
                                                        )
                                                  : Text(
                                                      entry.value.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                            )),
                                          )
                                          .toList(),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
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
