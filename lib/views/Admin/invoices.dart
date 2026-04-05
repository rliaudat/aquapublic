import 'dart:async';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/providers/admin_invoice_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // Variables
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List towns = [];
  List allData = [];
  List filteredData = [];
  Map<String, dynamic>? _selectedTown;

  int currentPage = 0;
  int totalPages = 0;

  TextEditingController searchController = TextEditingController();

  loadTowns() {
    if (context.read<UserProvider>().user!.role == 'Admin') {
      context.read<AdminInvoiceProvider>().setIsLoading(true);
      TownServices.fetchAll().then((data) {
        towns = data.map((doc) {
          return {
            'id': doc.id,
            'name': doc.name,
          };
        }).toList();
        _selectedTown = towns.first;
        loadData();
      });
    } else if (context.read<UserProvider>().user!.role == 'Manager') {
      towns.add(context.read<UserProvider>().user!.town);
      if (towns.isNotEmpty) {
        _selectedTown = towns.first;
        loadData();
      }
    } else if (context.read<UserProvider>().user!.role == 'Inspector') {
      towns.addAll(context.read<UserProvider>().user!.town);
      if (towns.isNotEmpty) {
        _selectedTown = towns.first;
        loadData();
      }
    }
  }

  loadData() {
    context.read<AdminInvoiceProvider>().setIsLoading(true);
    firestore
        .collection('readings')
        .where('townId', isEqualTo: _selectedTown?['id'] ?? 'No ID')
        .snapshots()
        .listen((querySnapshot) async {
      final readings = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();

        if (data['houseId'] != null) {
          final houseDoc =
              await firestore.collection('house').doc(data['houseId']).get();

          if (houseDoc.exists) {
            data['houseData'] = {
              'id': houseDoc.id,
              ...houseDoc.data() as Map<String, dynamic>,
            };
          } else {
            data['houseData'] = null;
          }
        }
        return data;
      }).toList());
      context.read<AdminInvoiceProvider>().setIsLoading(false);
      allData = readings;
      filteredData = allData;
      totalPages = (allData.length / 10).ceil();
    }).onError((e) {
      debugPrint('Error loading data: $e');
    });
  }

  @override
  void initState() {
    loadTowns();
    super.initState();
  }

  showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this invoice?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                pop(context);
              },
            ),
            TextButton(
              child: const Text('Yes, Delete'),
              onPressed: () {
                pop(context);
                deleteInvoice(item);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteInvoice(Map<String, dynamic> item) async {
    String id = item['id'];
    try {
      await firestore.collection('readings').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
    }
  }

  Future<void> showEditDialog(Map<String, dynamic> item) async {
    TextEditingController lastReadingController =
        TextEditingController(text: item['previousReading'].toString());
    TextEditingController readingController =
        TextEditingController(text: item['reading'].toString());
    TextEditingController consumptionController =
        TextEditingController(text: item['units'].toString());
    TextEditingController dateController =
        TextEditingController(text: dateFromTimestamp(item['date']));
    TextEditingController consumptionDaysController =
        TextEditingController(text: item['consumptionDays'].toString());
    TextEditingController amountController =
        TextEditingController(text: item['amount'].toString());

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(dateController.text),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != DateTime.parse(dateController.text)) {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last Reading',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: lastReadingController,
                decoration:
                    const InputDecoration(hintText: 'Enter last reading'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text('Current Reading',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: readingController,
                decoration:
                    const InputDecoration(hintText: 'Enter current reading'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text('Consumption',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: consumptionController,
                decoration:
                    const InputDecoration(hintText: 'Enter consumption'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select date',
                  prefixIcon: Icon(Icons.calendar_today, color: borderColor),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  await _selectDate(context);
                },
              ),
              const SizedBox(height: 10),
              const Text('Consumption Days',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: consumptionDaysController,
                decoration:
                    const InputDecoration(hintText: 'Enter consumption days'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text('Amount \$',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: Icon(Icons.attach_money, color: borderColor),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                pop(context);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                unFocus(context);
                pop(context);
                updateInvoice(
                  item,
                  double.parse(lastReadingController.text),
                  double.parse(readingController.text),
                  double.parse(consumptionController.text),
                  dateController.text,
                  int.parse(consumptionDaysController.text),
                  double.parse(amountController.text),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateInvoice(
      Map<String, dynamic> item,
      double lastReading,
      double reading,
      double consumption,
      String date,
      int consumptionDaysController,
      double amount) async {
    String id = item['id'];
    try {
      // Update the document in the reading collection
      await firestore.collection('readings').doc(id).update({
        'previousReading': lastReading,
        'reading': reading,
        'units': consumption,
        'date': Timestamp.fromDate(DateTime.parse(date)),
        'consumptionDays': consumptionDaysController,
        'amount': amount,
      });
    } catch (e) {
      debugPrint('Error updating invoice: $e');
    }
  }

  void filterData() {
    String query = searchController.text;
    if (query.isEmpty) {
      filteredData = allData;
    } else {
      filteredData = allData.where((item) {
        return item['houseData']['name']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    }
    if (mounted) setState(() {});
  }

  Future<Uint8List> generateUtilityBillPdf(dynamic item) async {
    final houseId = item['houseId'];
    final townId = item['townId'];
    var readingHistory = [];

    var readingsSnapshot = await firestore
        .collection('readings')
        .orderBy('date', descending: true)
        .where('townId', isEqualTo: townId)
        .where('houseId', isEqualTo: houseId)
        .limit(12)
        .get();

    if (readingsSnapshot.docs.isNotEmpty) {
      // Store all readings
      readingHistory = readingsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } else {
      readingHistory = [];
    }

    final pdf = pw.Document();
    const headerColor = PdfColor.fromInt(0xff197ba9);
    const bgColor = PdfColor.fromInt(0xffefefef);

    final image = pw.MemoryImage(
        (await rootBundle.load('assets/images/icon.png')).buffer.asUint8List());

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
                                width: 30, height: 30, child: pw.Image(image)),
                            pw.SizedBox(width: 10),
                            pw.Text(
                              'AguaMED',
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
                            'AguaMed Powers Inc',
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                          pw.Text(
                            '+1 (123) 456-7890',
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                          pw.Text(
                            'info@aguamed.com',
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
                    'Invoice Details',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('House ID: ${item['houseData']['name']}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Consumption: ${item['units']} m³'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Amount: \$${item['amount']}'),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'Bill History',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Month', 'Consumption (m³)', 'Amount (\$)'],
                  data: List.generate(readingHistory.length, (index) {
                    var data = readingHistory[index];
                    return [
                      dateFromTimestamp(data['date']),
                      data['units'],
                      data['amount']
                    ];
                  }),
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child:
                      pw.Text('Previous Reading: ${item['previousReading']}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Current Reading: ${item['reading']}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Days: ${item['consumptionDays']}'),
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

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return Scaffold(
      appBar: isTablet
          ? null
          : const CustomAppBar(title: 'Invoices', showButton: true),
      body: Consumer<AdminInvoiceProvider>(
        builder: (context, provider, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isTablet ? const CustomDrawer() : Container(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isTablet
                          ? const CustomAppBar(
                              title: 'Invoices', showButton: false)
                          : Container(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: p),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Container(
                              height: 95,
                              width: width(context),
                              decoration: BoxDecoration(
                                color: greyColor,
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Town',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: darkGreyColor),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(radius),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: DropdownButtonFormField(
                                              items: towns.map((town) {
                                                return DropdownMenuItem(
                                                  value: town,
                                                  child: Text(town['name']),
                                                );
                                              }).toList(),
                                              onChanged: (_) {
                                                _selectedTown =
                                                    _ as Map<String, dynamic>;
                                                if (mounted) setState(() {});
                                                loadData();
                                              },
                                              value: _selectedTown,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey[200],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width(context) * 0.01),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'House',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: darkGreyColor),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            height: 45,
                                            child: TextField(
                                              controller: searchController,
                                              decoration: InputDecoration(
                                                hintText: "Search by house Id",
                                                prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                  color: borderColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width(context) * 0.01),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) =>
                                          provider.setSearchHover(true),
                                      onExit: (_) =>
                                          provider.setSearchHover(false),
                                      child: Button(
                                          color: provider.searchHover
                                              ? primaryColor
                                              : secondaryColor,
                                          borderRadius: radius,
                                          height: 45,
                                          width: width(context) / 9,
                                          text: 'Search',
                                          fontSize: width(context) * 0.0115,
                                          onPressed: () {
                                            filterData();
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            provider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : allData.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                      )
                                    : SizedBox(
                                        height: 600,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columnSpacing: 10,
                                            horizontalMargin: 0,
                                            columns: const [
                                              DataColumn(
                                                  label: Text('House No')),
                                              DataColumn(
                                                  label: Text('Last Readings')),
                                              DataColumn(
                                                  label:
                                                      Text('Current Readings')),
                                              DataColumn(
                                                  label: Text('Consumption')),
                                              DataColumn(label: Text('Date')),
                                              DataColumn(label: Text('Amount')),
                                              DataColumn(
                                                  label: Text('Export PDF')),
                                              DataColumn(
                                                  label: Text('Actions')),
                                            ],
                                            rows: getRows(),
                                          ),
                                        ),
                                      ),
                            const SizedBox(height: 16),
                            Row(
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
                                  'Page ${currentPage + 1} of $totalPages',
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
                            const SizedBox(height: 20),
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
  }

  List<DataRow> getRows() {
    int start = currentPage * 10;
    int end = start + 10;
    List<DataRow> rows = [];
    for (int i = start; i < end && i < filteredData.length; i++) {
      var item = filteredData[i];
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(item['houseData']['name'].toString())),
            DataCell(Text(item['previousReading'].toString())),
            DataCell(Text(item['reading'].toString())),
            DataCell(Text(item['units'].toString())),
            DataCell(Text(dateFromTimestamp(item['date']))),
            DataCell(Text('\$${item['amount'].toString()}')),
            DataCell(
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    showPdfPreview(context, item);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Export',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        'assets/images/waterBill.png',
                        width: 20,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DataCell(
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  icon: const Icon(Icons.more_vert),
                  items: [
                    const DropdownMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: Colors.blue)),
                    ),
                    DropdownMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: redColor)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'edit') {
                      showEditDialog(item);
                    } else if (value == 'delete') {
                      showDeleteConfirmation(item);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    return rows;
  }
}
