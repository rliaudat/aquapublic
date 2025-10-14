import 'dart:typed_data';

import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../theme.dart';

class SearchHouseScreen extends StatefulWidget {
  const SearchHouseScreen({super.key});

  @override
  State<SearchHouseScreen> createState() => _SearchHouseScreenState();
}

class _SearchHouseScreenState extends State<SearchHouseScreen> {
  TextEditingController searchController = TextEditingController();
  String searchValue = "";

  int currentPage = 0;
  int rowsPerPage = 10;

  String? _townId; // Store the selected town ID
  List<Map<String, dynamic>> _towns = []; // Cache the list of towns
  Map<String, String> _houseNames = {}; // Cache house names
  Stream<List<Map<String, dynamic>>>? _readingsStream;

  @override
  void initState() {
    super.initState();
    _fetchTowns(); // Fetch available towns initially
  }

  /// Fetch the list of towns from Firestore
  Future<void> _fetchTowns() async {
    try {
      final townSnapshot =
          await FirebaseFirestore.instance.collection('towns').get();
      final towns = townSnapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] ?? 'Unnamed Town'};
      }).toList();
      _towns = towns;
      if (towns.isNotEmpty) {
        _townId = towns.first['id']; // Default to the first town
        _initializeData(); // Fetch initial data for the default town
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Error fetching towns: $e");
    }
  }

  /// Fetch house names and readings for the selected town
  Future<void> _initializeData() async {
    if (_townId == null) return;

    try {
      // Fetch house names for the selected town
      final housesSnapshot = await FirebaseFirestore.instance
          .collection('towns')
          .doc(_townId)
          .collection('houses')
          .get();

      _houseNames = {
        for (var doc in housesSnapshot.docs)
          doc.id: doc.data()['name'] ?? 'Unknown'
      };
      if (mounted) setState(() {});

      // Initialize the readings stream
      _readingsStream = FirebaseFirestore.instance
          .collection('reading')
          .where('townId', isEqualTo: _townId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList());
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing data: $e");
    }
  }

  /// Show the town selection bottom sheet
  void _showTownSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Town',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _towns.length,
                  itemBuilder: (context, index) {
                    final town = _towns[index];
                    final isSelected = _townId == town['id'];
                    return GestureDetector(
                      onTap: () {
                        _townId = town['id'];
                        if (mounted) setState(() {});
                        _initializeData();
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          town['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> generateUtilityBillPdf(String houseId) async {
    final pdf = pw.Document();
    const headerColor = PdfColor.fromInt(0xff197ba9);
    const bgColor = PdfColor.fromInt(0xffefefef);

    final houseName = _houseNames[houseId] ?? "Unknown";

    // Fetch the specific readings for the houseId
    List<Map<String, dynamic>> houseReadings = [];
    if (_readingsStream != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('reading')
          .where('houseId', isEqualTo: houseId)
          .where('townId', isEqualTo: _townId)
          .get();

      houseReadings = snapshot.docs.map((doc) => doc.data()).toList();
    }

    // Calculate the monthly consumption and bill history
    List<List<String>> billHistoryData = [];
    String previousReading = "N/A";
    String currentReading = "N/A";
    int days = 0;
    String totalAmount = "N/A";

    if (houseReadings.isNotEmpty) {
      // Sort readings by date to ensure chronological order
      houseReadings.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      for (var reading in houseReadings) {
        final date = DateTime.parse(reading['date']);
        final monthName = _getMonthName(date.month); // Helper function
        final consumption = reading['reading']?.toString() ?? "0";
        final amount = reading['amount']?.toString() ?? "0";
        billHistoryData.add([monthName, consumption, '\$$amount']);
      }

      final lastReading = houseReadings.last;
      currentReading = lastReading['reading']?.toString() ?? "N/A";
      days = lastReading['days'] ?? 0;
      totalAmount = lastReading['amount']?.toString() ?? "N/A";

      final firstReading = houseReadings.first;
      previousReading = firstReading['previousreading']?.toString() ?? "N/A";
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            color: bgColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: headerColor,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'AGUAMED',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AguaMed Powers Inc',
                            style: const pw.TextStyle(color: PdfColors.white),
                          ),
                          pw.Text(
                            '+9218891919',
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

                // Invoice Details Section
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
                  child: pw.Text('House Name: $houseName'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Total Amount: \$$totalAmount'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Consumption: $currentReading m³'),
                ),
                pw.SizedBox(height: 16),

                // Bill History Section
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
                  data: billHistoryData,
                ),
                pw.SizedBox(height: 16),

                // Summary Section
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
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Previous Reading: $previousReading'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Current Reading: $currentReading'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text('Days: $days'),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    return month >= 1 && month <= 12 ? monthNames[month - 1] : "Unknown";
  }

  void showPdfPreview(BuildContext context, String houseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: 500,
            width: 400,
            child: PdfPreview(
              build: (format) async {
                return generateUtilityBillPdf(houseId);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Houses'),
          backgroundColor: primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.home_work),
              onPressed: () => _showTownSelectionSheet(context),
            ),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTablet) const CustomDrawer(),
            Expanded(
              child: Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _readingsStream == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _readingsStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          var data = snapshot.data!;
                          var filteredData = data.where((item) {
                            if (searchValue.isEmpty) return true;
                            return item['houseId']
                                .toString()
                                .contains(searchValue);
                          }).toList();

                          int totalRows = filteredData.length;
                          int totalPages = (totalRows / rowsPerPage).ceil();
                          var paginatedData = filteredData
                              .skip(currentPage * rowsPerPage)
                              .take(rowsPerPage)
                              .toList();

                          return Column(
                            children: [
                              const SizedBox(height: 30),
                              TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by house ID',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: whiteColor,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (value) {
                                  searchValue = value;
                                  currentPage = 0;
                                  if (mounted) setState(() {});
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 16,
                                    headingRowColor:
                                        WidgetStateProperty.resolveWith(
                                      (states) => primaryColor,
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('House Name')),
                                      DataColumn(label: Text('Consumption')),
                                      DataColumn(label: Text('Amount')),
                                      DataColumn(label: Text('Bill')),
                                    ],
                                    rows: paginatedData.map((item) {
                                      final houseName =
                                          _houseNames[item['houseId']] ??
                                              'Unknown';

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(houseName)),
                                          DataCell(
                                              Text('${item['reading']} m³')),
                                          DataCell(Text(
                                              '\$${item['amount'].toString()}')),
                                          DataCell(
                                            IconButton(
                                              icon: Icon(
                                                Icons.picture_as_pdf,
                                                color: secondaryColor,
                                              ),
                                              onPressed: () {
                                                showPdfPreview(
                                                    context, item['houseId']);
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
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
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
