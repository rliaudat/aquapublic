import 'dart:async';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/reading.dart';
import 'package:agua_med/providers/search_house_bill_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
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
  FirebaseFirestore instance = FirebaseFirestore.instance;
  var searchController = TextEditingController();
  Stream<List<Map>> _houseDataStream = const Stream.empty();

  @override
  void initState() {
    super.initState();
    _houseDataStream = getHouseDataStream(
      context.read<UserProvider>().user!.role == 'HouseOwner'
          ? [context.read<UserProvider>().user!.town['id']]
          : context
              .read<UserProvider>()
              .user!
              .town
              .map((element) => element['id'])
              .toList(),
    );
  }

  Future<Uint8List> generateUtilityBillPdf(
      dynamic item, List<Reading> readings) async {
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
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.SizedBox(
                              width: 30,
                              height: 30,
                              child: pw.Image(image),
                            ),
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
                  child: pw.Text('SearchHouseScreen.houseId'.tr() +
                      item['house'].name.toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['house'].lastReading != null
                      ? '${'SearchHouseScreen.consumption'.tr()}${item['house'].lastReading['units']} m³'
                      : '${'SearchHouseScreen.consumption'.tr()}-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['house'].lastReading != null
                      ? '${'SearchHouseScreen.amount'.tr()}\$${item['house'].lastReading['amount']}'
                      : '${'SearchHouseScreen.amount'.tr()}-'),
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
                  data: List.generate(readings.length, (index) {
                    var data = readings[index];
                    return [
                      dateFromTimestamp(data.date),
                      data.units,
                      data.amount,
                    ];
                  }),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'SearchHouseScreen.summary'.tr(),
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['house'].lastReading != null
                      ? '${'SearchHouseScreen.previousReading'.tr()}${item['house'].lastReading['previousReading']}'
                      : '${'SearchHouseScreen.previousReading'.tr()}-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['house'].lastReading != null
                      ? '${'SearchHouseScreen.currentReading'.tr()}${item['house'].lastReading['reading']}'
                      : '${'SearchHouseScreen.currentReading'.tr()}-'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(item['house'].lastReading != null
                      ? '${'SearchHouseScreen.days'.tr()}${item['house'].lastReading['consumptionDays']}'
                      : '${'SearchHouseScreen.days'.tr()}-'),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  void showPdfPreview(BuildContext context, item, List<Reading> readings) {
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
                      return generateUtilityBillPdf(item, readings);
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
    String? name;
    if (context.read<UserProvider>().user!.role == "Inspector") {
      name = selectedTown['name'];
    } else {
      name = context.read<UserProvider>().user!.town['name'];
    }

    return name ?? "SearchHouseScreen.searchHouses".tr();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Consumer<SearchHouseBillProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(townName()),
              backgroundColor: primaryColor,
            ),
            drawer: const CustomDrawer(),
            body: StreamBuilder(
                stream: _houseDataStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.data?.isEmpty ?? false) {
                    return const Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'No invoices available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    var data = snapshot.data ?? [];

                    data = data.where((item) {
                      final houseName =
                          item['house'].name.toString().toLowerCase();
                      return houseName
                          .contains(provider.searchValue.toLowerCase());
                    }).toList();

                    int totalRows = data.length;
                    int totalPages = (totalRows / provider.rowsPerPage).ceil();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            color: backgroundColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: p),
                                  child: Row(
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
                                      hintText:
                                          'SearchHouseScreen.searchByHouseId'
                                              .tr(),
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: whiteColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      provider.setSearchValue(value);
                                      provider.setCurrentPage(0);
                                      // filteredData = allData
                                      //     .where((item) => item['name']
                                      //         .toLowerCase()
                                      //         .contains(searchValue.toLowerCase()))
                                      //     .toList();
                                      // if (mounted) setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                        columnSpacing: 16,
                                        headingRowColor:
                                            WidgetStateProperty.resolveWith(
                                                (states) => primaryColor),
                                        headingTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        columns: [
                                          DataColumn(
                                              label: Text(
                                                  'SearchHouseScreen.houseIdColumn'
                                                      .tr())),
                                          DataColumn(
                                              label: Text(
                                                  'SearchHouseScreen.consumptionColumn'
                                                      .tr())),
                                          DataColumn(
                                              label: Text(
                                                  'SearchHouseScreen.amountColumn'
                                                      .tr())),
                                          DataColumn(
                                              label: Text(
                                                  'SearchHouseScreen.billColumn'
                                                      .tr())),
                                        ],
                                        rows: [
                                          for (Map item in data) ...{
                                            DataRow(
                                              cells: [
                                                DataCell(
                                                    Text(item['house'].name)),
                                                DataCell(Text(item['house']
                                                            .lastReading !=
                                                        null
                                                    ? '${item['house'].lastReading['units']}m³'
                                                    : '-')),
                                                DataCell(Text(item['house']
                                                            .lastReading !=
                                                        null
                                                    ? '\$${item['house'].lastReading['amount']}'
                                                    : '-')),
                                                DataCell(
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.picture_as_pdf,
                                                      color: secondaryColor,
                                                    ),
                                                    onPressed: () {
                                                      showPdfPreview(
                                                        context,
                                                        item,
                                                        item['readings'],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          }
                                        ]),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () {
                                          if (provider.currentPage > 0) {
                                            provider.setCurrentPage(
                                                provider.currentPage - 1);
                                          }
                                        },
                                      ),
                                      Text(
                                        '${'SearchHouseScreen.page'.tr()}${provider.currentPage + 1}${'SearchHouseScreen.of'.tr()}$totalPages',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          if (provider.currentPage <
                                              totalPages - 1) {
                                            provider.setCurrentPage(
                                                provider.currentPage + 1);
                                          }
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
                    );
                  }
                }),
          );
        },
      ),
    );
  }

  Stream<List<Map>> getHouseDataStream(List<dynamic> townIds) {
    return HouseServices.houseWithAllPastReadingStream(townIds).distinct();
  }
}
