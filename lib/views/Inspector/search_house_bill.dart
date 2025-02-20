import 'dart:async';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme.dart';

class SearchHouseScreen extends StatefulWidget {
  const SearchHouseScreen({super.key});

  @override
  State<SearchHouseScreen> createState() => _SearchHouseScreenState();
}

class _SearchHouseScreenState extends State<SearchHouseScreen> {
  // Variables
  FirebaseFirestore instance = FirebaseFirestore.instance;
  var searchController = TextEditingController();
  String searchValue = "";

  int currentPage = 0;
  int rowsPerPage = 10;

  List allData = [];
  List filteredData = [];

  // Functions
  loadData() {
    showLoader(context, 'SearchHouseScreen.justAMoment'.tr());
    var townId;
    if (userSD['role'] == "Inspector") {
      townId = selectedTown['id'];
    } else {
      townId = userSD['town']['id'];
    }

    instance.collection('towns').doc(townId).collection('houses').where('isDelete', isEqualTo: false).orderBy('createdAt').snapshots().listen((housesSnapshot) async {
      List<Map<String, dynamic>> tempAllData = [];

      for (var houseDoc in housesSnapshot.docs) {
        Map<String, dynamic> houseData = houseDoc.data();
        houseData['id'] = houseDoc.id;
        houseData['readings'] = [];
        houseData['lastReading'] = null;

        // Fetch all readings for this house
        var readingsSnapshot = await instance.collection('towns').doc(townId).collection('houses').doc(houseDoc.id).collection('reading').orderBy('date', descending: true).limit(12).get();

        if (readingsSnapshot.docs.isNotEmpty) {
          // Store all readings
          houseData['readings'] = readingsSnapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();

          // Store the latest reading
          houseData['lastReading'] = houseData['readings'].first;
        } else {
          houseData['readings'] = [];
          houseData['lastReading'] = null;
        }

        // Update the temporary list
        tempAllData = tempAllData.where((item) => item['id'] != houseDoc.id).toList();
        tempAllData.add(houseData);
      }
      pop(context);
      allData = tempAllData;
      filteredData = allData;
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    Timer(const Duration(milliseconds: 10), () {
      loadData();
    });

    super.initState();
  }

  Future<Uint8List> generateUtilityBillPdf(dynamic item) async {
    final pdf = pw.Document();
    const headerColor = PdfColor.fromInt(0xff197ba9);
    const bgColor = PdfColor.fromInt(0xffefefef);

    final ByteData bytes = await rootBundle.load('assets/images/icon.png');
    final List<int> imageData = bytes.buffer.asUint8List();
    final Uint8List image8List = Uint8List.fromList(imageData);
    final pw.MemoryImage image = pw.MemoryImage(image8List);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            color: bgColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: headerColor,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.SizedBox(width: 30, height: 30, child: pw.Image(image)),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          'SearchHouseScreen.aguaMed'.tr(),
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.white,
                          ),
                        ),
                      ]),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SearchHouseScreen.aguaMedPowersInc'.tr(),
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                          pw.Text(
                            'SearchHouseScreen.phoneNumber'.tr(),
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                          pw.Text(
                            'SearchHouseScreen.email'.tr(),
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'SearchHouseScreen.invoiceDetails'.tr(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('SearchHouseScreen.houseId'.tr() + item['name'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['lastReading'] != null ? 'SearchHouseScreen.consumption'.tr() + '${item['lastReading']['units']} m³' : 'SearchHouseScreen.consumption'.tr() + '-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['lastReading'] != null ? 'SearchHouseScreen.amount'.tr() + '\$${item['lastReading']['amount']}' : 'SearchHouseScreen.amount'.tr() + '-'),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'SearchHouseScreen.billHistory'.tr(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'SearchHouseScreen.month'.tr(),
                    'SearchHouseScreen.consumptionM3'.tr(),
                    'SearchHouseScreen.amountDollar'.tr()
                  ],
                  data: List.generate(item['readings'].length, (index) {
                    var data = item['readings'][index];
                    return [dateFromTimestamp(data['date']), data['units'], data['amount']];
                  }),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'SearchHouseScreen.summary'.tr(),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['lastReading'] != null ? 'SearchHouseScreen.previousReading'.tr() + '${item['lastReading']['previousReading']}' : 'SearchHouseScreen.previousReading'.tr() + '-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['lastReading'] != null ? 'SearchHouseScreen.currentReading'.tr() + '${item['lastReading']['reading']}' : 'SearchHouseScreen.currentReading'.tr() + '-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['lastReading'] != null ? 'SearchHouseScreen.days'.tr() + '${item['lastReading']['consumptionDays']}' : 'SearchHouseScreen.days'.tr() + '-'),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  void showPdfPreview(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(p),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      pop(context);
                    },
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 450,
                  width: MediaQuery.of(context).size.width,
                  child: PdfPreview(
                    canDebug: false,
                    build: (format) async {
                      return generateUtilityBillPdf(item);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  townName() {
    var name;
    if (userSD['role'] == "Inspector") {
      name = selectedTown['name'];
    } else {
      name = userSD['town']['name'];
    }

    return name ?? "SearchHouseScreen.searchHouses".tr();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    int totalRows = filteredData.length;
    int totalPages = (totalRows / rowsPerPage).ceil();

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(townName()),
          backgroundColor: primaryColor,
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTablet) const CustomDrawer(),
            Expanded(
              child: Container(
                color: backgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child:  Row(
                        children: [
                          Text(
                            'SearchHouseScreen.searchHouses'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(p),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'SearchHouseScreen.searchByHouseId'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: whiteColor,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          searchValue = value;
                          currentPage = 0;
                          filteredData = allData.where((item) => item['name'].toLowerCase().contains(searchValue.toLowerCase())).toList();
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowColor: WidgetStateProperty.resolveWith((states) => primaryColor),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          columns: [
                            DataColumn(label: Text('SearchHouseScreen.houseIdColumn'.tr())),
                            DataColumn(label: Text('SearchHouseScreen.consumptionColumn'.tr())),
                            DataColumn(label: Text('SearchHouseScreen.amountColumn'.tr())),
                            DataColumn(label: Text('SearchHouseScreen.billColumn'.tr())),
                          ],
                          rows: filteredData.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item['name'])),
                                DataCell(Text(item['lastReading'] != null ? '${item['lastReading']['units']}m³' : '-')),
                                DataCell(Text(item['lastReading'] != null ? '\$${item['lastReading']['amount']}' : '-')),
                                DataCell(
                                  IconButton(
                                    icon: Icon(
                                      Icons.picture_as_pdf,
                                      color: secondaryColor,
                                    ),
                                    onPressed: () {
                                      showPdfPreview(context, item);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: currentPage > 0
                                ? () => setState(() {
                                      currentPage--;
                                    })
                                : null,
                          ),
                          Text(
                            'SearchHouseScreen.page'.tr() + '${currentPage + 1}' + 'SearchHouseScreen.of'.tr() + '$totalPages',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: currentPage < totalPages - 1
                                ? () => setState(() {
                                      currentPage++;
                                    })
                                : null,
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
