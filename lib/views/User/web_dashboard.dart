// // ignore_for_file: curly_braces_in_flow_control_structures
// import 'package:agua_med/_helpers/helper.dart';
// import 'package:agua_med/_services/house_services.dart';
// import 'package:agua_med/_services/reading_services.dart';
// import 'package:agua_med/loading.dart';
// import 'package:agua_med/models/house.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:responsive_framework/responsive_framework.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:excel/excel.dart';
// import 'package:agua_med/Components/Drawer.dart';
// import 'package:agua_med/Components/bottomSheets/house_billing.dart';
// import 'package:agua_med/providers/user_provider.dart';
// import 'package:agua_med/theme.dart';
// import 'dart:html' as html;
// import 'dart:convert';
// import 'package:csv/csv.dart';

// class UserWebDashboardPage extends StatefulWidget {
//   const UserWebDashboardPage({super.key});

//   @override
//   State<UserWebDashboardPage> createState() => _UserWebDashboardPageState();
// }

// class _UserWebDashboardPageState extends State<UserWebDashboardPage> {
//   // Constants
//   static const _months = [
//     "January",
//     "February",
//     "March",
//     "April",
//     "May",
//     "June",
//     "July",
//     "August",
//     "September",
//     "October",
//     "November",
//     "December"
//   ];
//   static const _pageSizes = ["10", "15", "20"];
//   static const _houseTypes = ["Living", "Weekend", "All"];
//   static const _consumptionFilters = ["Low", "Medium", "High", "All"];
//   static const _measurementStatuses = ["Pending", "Complete", "All"];

//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // Add to your state class
//   DocumentSnapshot? _lastDocument; // Tracks last doc for pagination
//   bool _hasMoreData = true; // Tracks if more data exists
//   int _totalRecords = 0; // Total records count

//   // State variables
//   final List<Map<String, dynamic>> _towns = [];
//   List<Map<String, dynamic>> _tableData = [];
//   List<Map<String, dynamic>> _displayedData = [];

//   Map<String, dynamic>? _selectedTown;
//   String? _selectedMonth;
//   String? _selectedYear;
//   String _searchQuery = '';
//   String? _selectedHouseType;
//   String? _selectedConsumption;
//   String? _selectedMeasurementStatus;

//   int _currentPage = 1;
//   int _rowsPerPage = 10;
//   bool _isLoading = false;

//   // Services
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late final List<String> _years;

//   String _generateSafeId(String houseNumber, int month, int year) {
//     // Handle null/empty/N/A cases
//     if (houseNumber.isEmpty || houseNumber == 'N/A') {
//       return 'default_${month.toString().padLeft(2, '0')}_$year';
//     }

//     // Basic sanitization
//     var safeId = houseNumber
//         .toLowerCase()
//         .replaceAll(RegExp(r'[^a-z0-9]'), '_') // Replace special chars
//         .replaceAll(RegExp(r'_+'), '_'); // Collapse multiple underscores

//     // Ensure non-empty and limit length safely
//     safeId = safeId.isEmpty ? 'house' : safeId;
//     safeId = safeId.substring(0, safeId.length > 20 ? 20 : safeId.length);

//     return '${safeId}_${month.toString().padLeft(2, '0')}_$year';
//   }

//   // For readings
//   String _generateReadingId(String houseNumber, int month, int year) {
//     return 'rd_${_generateSafeId(houseNumber, month, year)}';
//   }

// // For invoices
//   String _generateInvoiceId(String houseNumber, int month, int year) {
//     return 'inv_${_generateSafeId(houseNumber, month, year)}';
//   }

//   @override
//   void initState() {
//     super.initState();
//     _selectedMonth = _months[DateTime.now().month - 1];
//     _selectedYear = DateTime.now().year.toString();
//     _years = List.generate(
//         DateTime.now().year - 2019, (index) => (2020 + index).toString());
//     _selectedHouseType = 'All'; // Set default value
//     _selectedConsumption = 'All'; // Set default value
//     _selectedMeasurementStatus = 'All'; // Set default value
//     _loadTowns();
//   }

//   bool _applyHouseTypeFilter(Map<String, dynamic> row) {
//     if (_selectedHouseType == null || _selectedHouseType == 'All') return true;
//     return row['House Type'] == _selectedHouseType;
//   }

//   bool _applyConsumptionFilter(Map<String, dynamic> row) {
//     if (_selectedConsumption == null || _selectedConsumption == 'All')
//       return true;
//     return row['Consumption Level'] == _selectedConsumption;
//   }

//   bool _applyMeasurementStatusFilter(Map<String, dynamic> row) {
//     if (_selectedMeasurementStatus == null ||
//         _selectedMeasurementStatus == 'All') {
//       return true;
//     }
//     return row['Measurement Status'] ==
//         _selectedMeasurementStatus?.toLowerCase();
//   }

//   Future<void> _importFromCsv() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv'],
//         withData: true,
//       );

//       if (result == null || result.files.first.bytes == null) return;

//       Uint8List fileBytes = result.files.first.bytes!;
//       String csvString = utf8.decode(fileBytes);

//       List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

//       if (rows.length <= 1) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('CSV must contain at least one data row')),
//         );
//         return;
//       }

//       List<Map<String, dynamic>> readingsToImport = [];
//       final now = DateTime.now();
//       final currentMonth = now.month;
//       final currentYear = now.year;

//       for (var row in rows.skip(1)) {
//         if (row.length < 5) continue;

//         try {
//           final houseNumber = row[0].toString();
//           final readingId =
//               _generateReadingId(houseNumber, currentMonth, currentYear);

//           readingsToImport.add({
//             'id': readingId,
//             'houseId': houseNumber,
//             'reading': double.tryParse(row[1].toString()) ?? 0.0,
//             'meterImageURL': row[2].toString(),
//             'consumptionDays': int.tryParse(row[3].toString()) ?? 0,
//             'comment': row[4].toString().isEmpty ? null : row[4].toString(),
//             'date': Timestamp.now(),
//           });
//         } catch (e) {
//           debugPrint('Error parsing CSV row: $e');
//         }
//       }

//       if (readingsToImport.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No valid reading data found in CSV')),
//         );
//         return;
//       }

//       // Confirm import
//       bool confirm = await showDialog<bool>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: Text('Import ${readingsToImport.length} readings?'),
//               content: Text(
//                   'Are you sure you want to import ${readingsToImport.length} readings?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   child: const Text('Import'),
//                 ),
//               ],
//             ),
//           ) ??
//           false;

//       if (!confirm) return;

//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator()),
//       );

//       int successCount = 0;
//       final batch = _firestore.batch();

//       for (var readingData in readingsToImport) {
//         try {
//           // Get house document by meter number
//           final houseQuery = await _firestore
//               .collection('house')
//               .where('meterNumber', isEqualTo: readingData['houseId'])
//               .limit(1)
//               .get();

//           if (houseQuery.docs.isEmpty) continue;

//           final houseDoc = houseQuery.docs.first;
//           final townDoc =
//               await _firestore.collection('town').doc(houseDoc['townID']).get();

//           // Get previous reading
//           final previousReadingQuery = await _firestore
//               .collection('readings')
//               .where('houseId', isEqualTo: readingData['houseId'])
//               .orderBy('date', descending: true)
//               .limit(1)
//               .get();

//           double previousReading = 0;
//           if (previousReadingQuery.docs.isNotEmpty) {
//             previousReading = previousReadingQuery.docs.first['reading'] ?? 0;
//           }

//           double unitPrice = townDoc['unitPrice'] ?? 0.0;
//           double units = readingData['reading'] - previousReading;
//           double amount = units * unitPrice;

//           // Use the generated ID for the reading
//           final docRef =
//               _firestore.collection('readings').doc(readingData['id']);

//           batch.set(docRef, {
//             'id': readingData['id'],
//             'houseId': readingData['houseId'],
//             'townId': houseDoc['townID'],
//             'inspectorId': context.read<UserProvider>().user?.uid ?? '',
//             'reading': readingData['reading'],
//             'previousReading': previousReading,
//             'units': units,
//             'previousUnits': previousReadingQuery.docs.isNotEmpty
//                 ? previousReadingQuery.docs.first['units'] ?? 0
//                 : 0,
//             'amount': amount,
//             'consumptionDays': readingData['consumptionDays'],
//             'meterImageURL': readingData['meterImageURL'],
//             'comment': readingData['comment'],
//             'readingStatus':
//                 readingData['comment'] == null ? 'approved' : 'pending',
//             'billingStatus': 'open',
//             'date': readingData['date'],
//             'isDelete': false,
//             'createdAt': Timestamp.now(),
//             'updatedAt': Timestamp.now(),
//           });

//           // Also create the invoice with the generated ID
//           final invoiceId = _generateInvoiceId(
//               readingData['houseId'], currentMonth, currentYear);
//           final invoiceRef = _firestore.collection('invoices').doc(invoiceId);

//           batch.set(invoiceRef, {
//             'id': invoiceId,
//             'houseId': readingData['houseId'],
//             'townId': houseDoc['townID'],
//             'readingId': readingData['id'],
//             'amount': amount,
//             'month': currentMonth,
//             'year': currentYear,
//             'status': 'unpaid',
//             'createdAt': Timestamp.now(),
//             'updatedAt': Timestamp.now(),
//           });

//           successCount++;
//         } catch (e) {
//           debugPrint('Error importing reading: $e');
//         }
//       }

//       await batch.commit();

//       if (mounted) Navigator.pop(context);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               'Successfully imported $successCount of ${readingsToImport.length} readings'),
//           duration: const Duration(seconds: 3),
//         ),
//       );

//       _loadData(reset: true);
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error importing readings: ${e.toString()}')),
//       );
//       debugPrint('Import error: $e');
//     }
//   }

//   Future<DocumentSnapshot?> _getInvoiceAmountForMonth(
//       String townId, String houseId, int month, int year) async {
//     try {
//       final invoiceQuery = await _firestore
//           .collection('invoices')
//           .where('townId', isEqualTo: townId)
//           .where('houseId', isEqualTo: houseId)
//           .where('month', isEqualTo: month)
//           .where('year', isEqualTo: year)
//           .limit(1)
//           .get();

//       if (invoiceQuery.docs.isEmpty) return null;

//       final amount = invoiceQuery.docs.last;
//       return amount;
//     } catch (e) {
//       debugPrint('Error fetching invoice amount: $e');
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>> _createExportRow(
//       Map<String, dynamic> houseData) async {
//     final monthIndex = _months.indexOf(_selectedMonth!) + 1;
//     final selectedYearInt = int.parse(_selectedYear!);
//     final invoice = await _getInvoiceAmountForMonth(
//       houseData['townID'],
//       houseData['id'],
//       monthIndex,
//       selectedYearInt,
//     );
//     return {
//       'Town': _selectedTown!['name'],
//       'House': houseData['name'],
//       'Month': _selectedMonth,
//       'Water Meter ID': houseData['meterNumber'],
//       'Previous Reading': houseData['lastReading'] != null
//           ? double.parse(houseData['lastReading']['previousReading'].toString())
//           : '',
//       'Previous Reading Date': "2025-01-20",
//       'Reading': houseData['lastReading'] != null
//           ? double.parse(houseData['lastReading']['reading'].toString())
//           : '',
//       'Reading Date': houseData['lastReading'] != null
//           ? DateFormat("yyyy-MM-dd")
//               .format((houseData['lastReading']['date'] as Timestamp).toDate())
//           : '',
//       'Days of Consumption': houseData['lastReading'] != null
//           ? int.parse(houseData['lastReading']['consumptionDays'].toString())
//           : '',
//       'Calculated Consumption': houseData['lastReading'] != null
//           ? double.parse(houseData['lastReading']['units'].toString())
//           : '',
//       'House Type': houseData['houseType'],
//       'Consumption Level': houseData['lastReading'] != null
//           ? _consumptionLevel(
//               houseData['houseType'],
//               houseData['cohabitants'],
//               (houseData['lastReading']['reading'] -
//                       houseData['lastReading']['previousReading'])
//                   .toDouble())
//           : '',
//       'Billing Status': houseData['lastReading'] != null
//           ? houseData['lastReading']['billingStatus']
//           : '',
//       'Measurement Status': houseData['lastReading'] != null
//           ? houseData['lastReading']['measurementStatus']
//           : 'pending',
//       'View Image': houseData['lastReading'] != null
//           ? houseData['lastReading']['meterImageURL']
//           : '',
//       'Amount': invoice == null
//           ? ''
//           : double.parse((invoice['amount'] as num).toStringAsFixed(2)),
//     };
//   }

//   Future<void> _exportToExcel() async {
//     // Show loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       // Fetch all houses for export
//       final querySnapshot = await _firestore
//           .collection('house')
//           .where('townID', isEqualTo: _selectedTown!['id'])
//           .where('isDelete', isEqualTo: false)
//           .orderBy('createdAt')
//           .get();

//       List<Map<String, dynamic>> exportData = [];

//       // Process all houses for export
//       for (final houseDoc in querySnapshot.docs) {
//         final houseData = houseDoc.data()..['id'] = houseDoc.id;
//         houseData['lastReading'] = null;

//         // Get the latest reading for this house
//         final readingSnapshot = await _firestore
//             .collection('readings')
//             .where('houseId', isEqualTo: houseData['id'])
//             .orderBy('date', descending: true)
//             .limit(1)
//             .get();

//         if (readingSnapshot.docs.isNotEmpty) {
//           houseData['lastReading'] = {
//             'id': readingSnapshot.docs.first.id,
//             ...readingSnapshot.docs.first.data()
//           };
//         }

//         // Create export row
//         final rowData = await _createExportRow(houseData);
//         exportData.add(rowData);
//       }

//       // Generate Excel file
//       final excel = Excel.createExcel();
//       final sheet = excel['Sheet1'];

//       // Add headers
//       if (exportData.isNotEmpty) {
//         final headers = exportData.first.keys.toList();
//         for (int i = 0; i < headers.length; i++) {
//           sheet
//               .cell(CellIndex.indexByString("${String.fromCharCode(65 + i)}1"))
//               .value = TextCellValue(headers[i]);
//         }

//         // Add data
//         for (int rowIndex = 0; rowIndex < exportData.length; rowIndex++) {
//           final row = exportData[rowIndex];
//           for (int colIndex = 0; colIndex < headers.length; colIndex++) {
//             final key = headers[colIndex];
//             sheet
//                 .cell(CellIndex.indexByString(
//                     "${String.fromCharCode(65 + colIndex)}${rowIndex + 2}"))
//                 .value = TextCellValue(row[key]?.toString() ?? '');
//           }
//         }
//       }

//       // Save and download
//       excel.save(
//           fileName:
//               'water_consumption_export_${DateTime.now().millisecondsSinceEpoch}.xlsx')!;

//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Export failed: ${e.toString()}')),
//       );
//       debugPrint('Export error: $e');
//     }
//   }

//   void _loadTowns() {
//     _isLoading = true;
//     if (mounted) setState(() {});

//     final userProvider = context.read<UserProvider>();
//     if (userProvider.user?.role == 'Admin') {
//       _firestore.collection('town').snapshots().listen((querySnapshot) async {
//         _towns.clear();
//         _towns.addAll(await Future.wait(querySnapshot.docs.map((doc) async {
//           return {'id': doc.id, 'name': doc['name']};
//         })));
//         _selectedTown = _towns.last;
//         _loadData(reset: true);
//       }).onError((e) {
//         debugPrint('Error loading towns: $e');
//         _isLoading = false;
//         if (mounted) setState(() {});
//       });
//     } else {
//       _towns.add(userProvider.user!.town);
//       _selectedTown = userProvider.user!.town;
//       _loadData(reset: true);
//     }
//   }

//   String _consumptionLevel(
//       String? houseType, int? cohabitants, double? consumption) {
//     if (houseType == null ||
//         cohabitants == null ||
//         consumption == null ||
//         cohabitants < 2 ||
//         cohabitants > 6) {
//       return "Unknown";
//     }

//     final thresholds = _getConsumptionThresholds(houseType, cohabitants);
//     if (thresholds == null) return "Unknown";

//     if (consumption < thresholds.low) return "Low";
//     if (consumption <= thresholds.medium) return "Medium";
//     return "High";
//   }

//   ({double low, double medium})? _getConsumptionThresholds(
//       String houseType, int cohabitants) {
//     const livingThresholds = {
//       2: (low: 22.0, medium: 39.0),
//       3: (low: 27.0, medium: 45.0),
//       4: (low: 33.0, medium: 63.0),
//       5: (low: 39.0, medium: 84.0),
//       6: (low: 45.0, medium: 108.0),
//     };

//     const weekendThresholds = {
//       2: (low: 5.84, medium: 10.4),
//       3: (low: 7.2, medium: 12.0),
//       4: (low: 8.8, medium: 16.8),
//       5: (low: 10.4, medium: 22.4),
//       6: (low: 12.0, medium: 28.8),
//     };

//     return houseType == "Living"
//         ? livingThresholds[cohabitants]
//         : weekendThresholds[cohabitants];
//   }

//   // bool _checkReading(Map<String, dynamic> item) {
//   //   final lastReading = item['lastReading'];
//   //   if (lastReading == null ||
//   //       lastReading.isEmpty ||
//   //       lastReading['date'] == null) {
//   //     return false;
//   //   }

//   //   final timestamp = lastReading['date'] as Timestamp;
//   //   final lastReadingDate = timestamp.toDate();
//   //   final now = DateTime.now();
//   //   return lastReadingDate.year == now.year &&
//   //       lastReadingDate.month == now.month;
//   // }

//   Future<void> _loadData({bool reset = false}) async {
//     if (_selectedTown == null) return;

//     if (reset) {
//       _lastDocument = null;
//       _hasMoreData = true;
//       _tableData.clear();
//       _currentPage = 1;
//       if (mounted) setState(() {});
//     }

//     if (!_hasMoreData) return;

//     _isLoading = true;
//     if (mounted) setState(() {});

//     try {
//       // Get month and year for ID generation
//       final monthIndex = _months.indexOf(_selectedMonth!) + 1;
//       final selectedYearInt = int.parse(_selectedYear!);

//       Query query = _firestore
//           .collection('house')
//           .where('townID', isEqualTo: _selectedTown!['id'])
//           .where('isDelete', isEqualTo: false)
//           .orderBy('createdAt')
//           .limit(_rowsPerPage);

//       if (_lastDocument != null) {
//         query = query.startAfterDocument(_lastDocument!);
//       }

//       final querySnapshot = await query.get();

//       if (querySnapshot.docs.isEmpty) {
//         _hasMoreData = false;
//         _isLoading = false;
//         if (mounted) setState(() {});
//         return;
//       }

//       _lastDocument = querySnapshot.docs.last;

//       // Get total count (only once)
//       if (_totalRecords == 0) {
//         final countQuery = await _firestore
//             .collection('house')
//             .where('townID', isEqualTo: _selectedTown!['id'])
//             .where('isDelete', isEqualTo: false)
//             .count()
//             .get();
//         _totalRecords = countQuery.count ?? 0;
//       }

//       // Prepare all the futures we'll need
//       final futures = querySnapshot.docs.map((houseDoc) async {
//         final houseData = houseDoc.data() as Map<String, dynamic>;

//         // Generate the reading and invoice IDs
//         final readingId =
//             _generateReadingId(houseData['id'], monthIndex, selectedYearInt);
//         final invoiceId =
//             _generateInvoiceId(houseData['id'], monthIndex, selectedYearInt);

//         // Fetch reading and invoice in parallel
//         final results = await Future.wait([
//           _firestore.collection('readings').doc(readingId).get(),
//           _firestore.collection('invoices').doc(invoiceId).get(),
//         ]);

//         final readingDoc = results[0];
//         final invoiceDoc = results[1];

//         return {
//           'houseData': houseData,
//           'reading': readingDoc.exists
//               ? readingDoc.data() as Map<String, dynamic>
//               : null,
//           'invoice': invoiceDoc.exists
//               ? invoiceDoc.data() as Map<String, dynamic>
//               : null,
//         };
//       }).toList();

//       // Wait for all house data to load
//       final allHouseData = await Future.wait(futures);

//       // Process all the data
//       for (final data in allHouseData) {
//         await _updateHouseData(
//           data['houseData'],
//           reading: data['reading'],
//           invoice: data['invoice'],
//         );
//       }

//       _isLoading = false;
//       if (mounted) setState(() {});
//     } catch (e) {
//       debugPrint('Error loading data: $e');
//       _isLoading = false;
//       if (mounted) setState(() {});
//     }
//   }

//   Future<void> _showStatusDialog(
//       BuildContext context,
//       String readingId,
//       String comment,
//       String houseId,
//       String townId,
//       Map<String, dynamic> lastReadingData) async {
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Reason:'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(comment.isNotEmpty ? comment : 'No comment provided'),
//             const SizedBox(height: 16),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             style: ButtonStyle(
//               backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
//             ),
//             onPressed: () => Navigator.pop(context, false), // Reject
//             child: const Text(
//               'Reject',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//             ),
//           ),
//           ElevatedButton(
//             style: ButtonStyle(
//               backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
//             ),
//             onPressed: () => Navigator.pop(context, true), // Approve
//             child: const Text(
//               'Approve',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (result != null) {
//       try {
//         if (result) {
//           // Approve action - update both reading and house documents
//           await _firestore.collection('readings').doc(readingId).update({
//             'readingStatus': 'approved',
//           });
//         } else {
//           // Reject action - just update reading status
//           deleteInvoice(townId, houseId);
//         }

//         // Refresh the data
//         _loadData(reset: true);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result ? 'Reading approved' : 'Reading rejected'),
//           ),
//         );
//       } catch (e) {
//         debugPrint('Error updating reading status: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to update status: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   // Updated house data processing
//   Future<void> _updateHouseData(
//     Map<String, dynamic>? houseData, {
//     Map<String, dynamic>? reading,
//     Map<String, dynamic>? invoice,
//   }) async {
//     final houseId = houseData!['id'];
//     final townId = houseData['townID'];
//     final hasValidReading = reading != null;

//     final rowData = {
//       "_houseId": houseId,
//       "_townId": townId,
//       "_readingId": reading?['id'],
//       "_invoiceId": invoice?['id'],
//       "House ID": houseData['name'] ?? '',
//       "Month": _selectedMonth,
//       "Water Meter ID": houseData['meterNumber'] ?? '',
//       "Previous Reading": "${reading?['previousReading'] ?? 0} m³",
//       "Previous Reading Date":
//           "2025-01-20", // Update this dynamically if needed
//       "Reading": hasValidReading ? "${reading['reading'] ?? 0} m³" : "",
//       "Reading Date": hasValidReading
//           ? DateFormat("yyyy-MM-dd")
//               .format((reading['date'] as Timestamp).toDate())
//           : '',
//       "Days of Consumption":
//           hasValidReading ? (reading['consumptionDays'] ?? 0).toString() : '',
//       "Calculated Consumption": hasValidReading
//           ? "${(reading['reading'] ?? 0) - (reading['previousReading'] ?? 0)} m³"
//           : '',
//       if (context.read<UserProvider>().user?.role != 'HouseOwner')
//         "House Type": houseData['houseType'] ?? '',
//       "Consumption Level": hasValidReading
//           ? _consumptionLevel(houseData['houseType'], houseData['cohabitants'],
//               (reading['reading'] - reading['previousReading']).toDouble())
//           : "",
//       "Billing Status": reading?['billingStatus'] ?? "",
//       "Measurement Status":
//           hasValidReading ? reading['measurementStatus'] : "pending",
//       "View Image": reading?['meterImageURL'] ?? '',
//       if (context.read<UserProvider>().user?.role != 'HouseOwner')
//         "Reading Status": reading?['readingStatus'] == 'pending'
//             ? context.read<UserProvider>().user?.role == 'HouseOwner'
//                 ? Text(
//                     reading!['readingStatus'],
//                     style: const TextStyle(fontSize: 11, color: Colors.green),
//                   )
//                 : ElevatedButton(
//                     onPressed: () => _showStatusDialog(
//                       context,
//                       reading?['id'],
//                       reading?['comment'] ?? '',
//                       houseId,
//                       townId,
//                       {
//                         'amount': reading?['amount'],
//                         'consumptionDays': reading?['consumptionDays'],
//                         'date': reading?['date'],
//                         'inspectorId': reading?['inspectorId'],
//                         'meterImageURL': reading?['meterImageURL'],
//                         'previousReading': reading?['previousReading'],
//                         'previousUnits': reading?['previousUnits'],
//                         'reading': reading?['reading'],
//                         'units': reading?['units'],
//                       },
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                     ),
//                     child: const Text(
//                       'Check Reason',
//                       style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600),
//                     ),
//                   )
//             : Text(
//                 reading?['readingStatus'] ?? '',
//                 style: const TextStyle(fontSize: 11, color: Colors.green),
//               ),
//       "Amount":
//           invoice == null ? '-' : (invoice['amount'] as num).toStringAsFixed(2),
//       if (context.read<UserProvider>().user?.role != 'HouseOwner')
//         "Edit": () {},
//     };

//     // Update or add row
//     final existingIndex = _tableData.indexWhere(
//       (row) => row["House ID"] == houseData['name'],
//     );
//     if (existingIndex >= 0) {
//       _tableData[existingIndex] = rowData;
//     } else {
//       _tableData.add(rowData);
//     }

//     _updateDisplayedData();
//   }

//   void _updateDisplayedData() {
//     // Filter based on search query
//     final filteredData = _tableData.where((row) {
//       return row["House ID"]
//               .toString()
//               .toLowerCase()
//               .contains(_searchQuery.toLowerCase()) &&
//           _applyHouseTypeFilter(row) &&
//           _applyConsumptionFilter(row) &&
//           _applyMeasurementStatusFilter(row);
//     }).toList();

//     // Apply pagination
//     final start = (_currentPage - 1) * _rowsPerPage;
//     final end = start + _rowsPerPage > filteredData.length
//         ? filteredData.length
//         : start + _rowsPerPage;

//     _displayedData.clear();
//     _displayedData.addAll(filteredData.sublist(start, end));

//     if (mounted) setState(() {});
//   }

//   // UI Components
//   Widget _buildDropdown<T>({
//     required String label,
//     required List<T> items,
//     required T? value,
//     required Function(T?) onChanged,
//     String Function(T item)? itemToString,
//   }) {
//     return Container(
//       height: 46,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(radius),
//       ),
//       child: DropdownButtonFormField<T>(
//         decoration: InputDecoration(
//           label: Text(
//             label,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         items: items
//             .map((item) => DropdownMenuItem(
//                   value: item,
//                   child: Text(itemToString?.call(item) ?? item.toString()),
//                 ))
//             .toList(),
//         onChanged: onChanged,
//         value: value,
//       ),
//     );
//   }

//   Widget _buildPaginationControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         const Text('Rows per page:', style: TextStyle(fontSize: 12)),
//         const SizedBox(width: 10),
//         SizedBox(
//           width: 75,
//           child: _buildDropdown<String>(
//             label: '',
//             items: _pageSizes,
//             value: _rowsPerPage.toString(),
//             onChanged: (value) {
//               _rowsPerPage = int.parse(value!);
//               _loadData(reset: true); // Reset and reload with new page size
//             },
//           ),
//         ),
//         const SizedBox(width: 20),
//         Text(
//           '${((_currentPage - 1) * _rowsPerPage) + 1} - '
//           '${(_currentPage * _rowsPerPage).clamp(0, _totalRecords)} of '
//           '$_totalRecords',
//           style: const TextStyle(fontSize: 12),
//         ),
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios, size: 18),
//           onPressed: _currentPage > 1
//               ? () {
//                   _currentPage--;
//                   _loadData(reset: true);
//                 }
//               : null,
//           color: _currentPage > 1 ? Colors.black : Colors.grey,
//         ),
//         IconButton(
//           icon: const Icon(Icons.arrow_forward_ios, size: 18),
//           onPressed: _hasMoreData
//               ? () {
//                   _currentPage++;
//                   _loadData();
//                 }
//               : null,
//           color: _hasMoreData ? Colors.black : Colors.grey,
//         ),
//       ],
//     );
//   }

//   Widget _buildDataTable(int currentMonth, int currentYear) {
//     if (_tableData.isEmpty) return const SizedBox.shrink();

//     final columns = _tableData.first.keys
//         .where((header) => !header.startsWith('_'))
//         .map((key) => DataColumn(
//               label: Center(
//                 child: SizedBox(
//                   width: MediaQuery.of(context).size.width *
//                       (context.read<UserProvider>().user?.role != 'HouseOwner'
//                           ? 0.054
//                           : 0.065),
//                   child: Text(
//                     key,
//                     style: TextStyle(
//                       fontSize: 9.5,
//                       color: whiteColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     softWrap: true,
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ))
//         .toList();

//     final filteredData = _displayedData
//         .where((row) => row["House ID"]
//             .toString()
//             .toLowerCase()
//             .contains(_searchQuery.toLowerCase()))
//         .toList();

//     return Expanded(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.vertical,
//           child: DataTable(
//             headingRowColor: WidgetStateProperty.all(primaryColor),
//             columnSpacing: 2,
//             columns: columns,
//             rows: filteredData
//                 .map((row) => DataRow(
//                       cells: row.entries
//                           .where((entry) => !entry.key.startsWith('_'))
//                           .map((entry) => DataCell(
//                                 SizedBox(
//                                   width: MediaQuery.of(context).size.width *
//                                       (context
//                                                   .read<UserProvider>()
//                                                   .user
//                                                   ?.role !=
//                                               'HouseOwner'
//                                           ? 0.054
//                                           : 0.065),
//                                   child: _buildDataCell(
//                                     entry.key,
//                                     entry.value,
//                                     row,
//                                     currentMonth,
//                                     currentYear,
//                                   ),
//                                 ),
//                               ))
//                           .toList(),
//                     ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDataCell(String key, dynamic value, dynamic readingData,
//       int currentMonth, int currentYear) {
//     if (key == 'View Image') {
//       return value == null
//           ? const Text('')
//           : IconButton(
//               onPressed: () {
//                 final imageUrl = value.toString();
//                 final htmlContent = '''
//                 <html>
//                   <head><title>Image Preview</title></head>
//                   <body style="margin:10">
//                     <img src="$imageUrl" style="width:100%;height:auto;" />
//                   </body>
//                 </html>
//                 ''';
//                 final blob = html.Blob([htmlContent], 'text/html');
//                 final url = html.Url.createObjectUrlFromBlob(blob);
//                 html.window.open(url, '_blank');
//               },
//               icon: const Icon(Icons.image),
//             );
//     } else if (key == 'Edit') {
//       return DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           icon: const Icon(Icons.more_vert),
//           items: [
//             const DropdownMenuItem(
//               value: 'edit',
//               child: Text('Edit', style: TextStyle(color: Colors.blue)),
//             ),
//             DropdownMenuItem(
//               value: 'delete',
//               child: Text('Delete', style: TextStyle(color: redColor)),
//             ),
//           ],
//           onChanged: (value) async {
//             if (value == 'edit') {
//               DocumentSnapshot? checkReading = await ReadingServices.fetchByID(
//                   readingData['_houseId'], currentMonth, currentYear);
//               if (checkReading == null) {
//                 showToast(context,
//                     msg: 'This house reading is not currently taken!'.tr());
//               } else {
//                 showEditDialog({
//                   'readingData': readingData,
//                   "_readingId": readingData['_readingId'],
//                   "_invoiceId": readingData['_invoiceId'],
//                   'previousReading':
//                       readingData['Previous Reading'].split(' ').first,
//                   'reading': readingData['Reading'].split(' ').first,
//                   'units': readingData['Calculated Consumption'],
//                   'date': readingData['Reading Date'] == ''
//                       ? null
//                       : Timestamp.fromDate(
//                           DateTime.parse(readingData['Reading Date'])),
//                   'consumptionDays': readingData['Days of Consumption'],
//                   'amount': readingData['Amount'] ?? '',
//                   'measurementStatus': readingData['Measurement Status'],
//                 });
//               }
//             } else if (value == 'delete') {
//               showDeleteConfirmation({
//                 "_houseId": readingData['_houseId'],
//                 "_townId": readingData['_townId'],
//               });
//             }
//           },
//         ),
//       );
//     } else if (key == 'Reading Status') {
//       // Return the widget as-is if it's a button
//       if (value is Widget) return value;
//       return Text(
//         value.toString(),
//         style: TextStyle(
//           fontSize: 9.5,
//           color: value == 'rejected' ? Colors.red : Colors.green,
//         ),
//         softWrap: true,
//         textAlign: TextAlign.center,
//       );
//     }
//     return Text(
//       value.toString(),
//       style: const TextStyle(fontSize: 11),
//       softWrap: true,
//       textAlign: TextAlign.center,
//     );
//   }

//   showDeleteConfirmation(Map<String, dynamic> item) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Confirmation'),
//           content: const Text('Are you sure you want to delete this invoice?'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 pop(context);
//               },
//             ),
//             TextButton(
//               child: const Text('Yes, Delete'),
//               onPressed: () {
//                 pop(context);
//                 deleteInvoice(item['_townId'], item['_houseId']);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> deleteInvoice(String? townID, String? houseID) async {
//     try {
//       final houseId = houseID;
//       final townId = townID;

//       if (houseId == null || townId == null) {
//         throw Exception('Missing required IDs for deletion');
//       }

//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator()),
//       );

//       // Get the latest 2 readings for this house
//       final readingsSnapshot = await _firestore
//           .collection('readings')
//           .where('houseId', isEqualTo: houseId)
//           .where('townId', isEqualTo: townId)
//           .orderBy('date', descending: true)
//           .limit(2)
//           .get();

//       if (readingsSnapshot.docs.isEmpty) {
//         throw Exception('No readings found for this house');
//       }

//       // Delete the specified reading
//       _firestore
//           .collection('readings')
//           .doc(readingsSnapshot.docs.first.id)
//           .delete();

//       // If there's a second reading, update the house document with it
//       if (readingsSnapshot.docs.length > 1) {
//         final secondReading = readingsSnapshot.docs[1];
//         _firestore.collection('house').doc(houseId).update({
//           'lastReading': {
//             'reading': secondReading['reading'],
//             'previousReading': secondReading['previousReading'],
//             'previousUnits': secondReading['previousUnits'],
//             'units': secondReading['units'],
//             'amount': secondReading['amount'],
//             'consumptionDays': secondReading['consumptionDays'],
//             'date': secondReading['date'],
//             'meterImageURL': secondReading['meterImageURL'],
//             'inspectorId': secondReading['inspectorId'],
//           },
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//       } else {
//         // No previous reading exists, clear the lastReading field
//         _firestore.collection('house').doc(houseId).update({
//           'lastReading': null,
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//       }

//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Reading deleted successfully')),
//         );
//         _loadData(reset: true); // Refresh the data
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting reading: ${e.toString()}')),
//         );
//       }
//       debugPrint('Error deleting reading: $e');
//     }
//   }

//   // void _showEditBillingBottomSheet(
//   //     BuildContext context, Map<String, dynamic> reading) {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     isScrollControlled: true,
//   //     backgroundColor: Colors.transparent,
//   //     builder: (context) {
//   //       // Fetch the invoice data for this reading
//   //       return FutureBuilder<DocumentSnapshot>(
//   //         future: FirebaseFirestore.instance
//   //             .collection('invoices')
//   //             .where('reading.id', isEqualTo: reading['id'])
//   //             .limit(1)
//   //             .get()
//   //             .then((snapshot) => snapshot.docs.first),
//   //         builder: (context, snapshot) {
//   //           if (snapshot.connectionState == ConnectionState.waiting) {
//   //             return const Center(child: CircularProgressIndicator());
//   //           }
//   //           if (!snapshot.hasData) {
//   //             return const Center(
//   //                 child: Text('No invoice found for this reading'));
//   //           }

//   //           final invoice = snapshot.data!.data() as Map<String, dynamic>;
//   //           return EditHouseBillingDialog(
//   //             invoice: {
//   //               ...invoice,
//   //               'id': snapshot.data!.id,
//   //               'houseName': reading['House ID'] ?? 'Unknown House',
//   //             },
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
//     final isHouseOwner =
//         context.read<UserProvider>().user?.role == 'HouseOwner';

//     return Scaffold(
//       drawer: isDesktop ? const CustomDrawer() : null,
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         title: Text(
//           "Readings",
//           style: TextStyle(
//             color: whiteColor,
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                           child: _buildDropdown<Map<String, dynamic>>(
//                         label: 'Town ID',
//                         items: _towns,
//                         value: _selectedTown,
//                         onChanged: (value) {
//                           _selectedTown = value;
//                           _lastDocument = null;
//                           _totalRecords = 0;
//                           _loadData(reset: true);
//                         },
//                         itemToString: (town) => town['name'],
//                       )),
//                       const SizedBox(width: 10),
//                       Expanded(
//                           child: _buildDropdown<String>(
//                         label: 'Month',
//                         items: _months,
//                         value: _selectedMonth,
//                         onChanged: (value) {
//                           _selectedMonth = value;
//                           _loadData(reset: true);
//                         },
//                       )),
//                       const SizedBox(width: 10),
//                       Expanded(
//                           child: _buildDropdown<String>(
//                         label: 'Year',
//                         items: _years,
//                         value: _selectedYear,
//                         onChanged: (value) {
//                           _selectedYear = value;
//                           _loadData(reset: true);
//                         },
//                       )),
//                       const SizedBox(width: 10),
//                       Expanded(
//                           child: _buildDropdown<String>(
//                         label: 'House Type',
//                         items: _houseTypes,
//                         value: _selectedHouseType,
//                         onChanged: (value) {
//                           _selectedHouseType = value;
//                           _updateDisplayedData();
//                         },
//                       )),
//                       const SizedBox(width: 10),
//                       Expanded(
//                           child: _buildDropdown<String>(
//                         label: 'Consumption Filter',
//                         items: _consumptionFilters,
//                         value: _selectedConsumption,
//                         onChanged: (value) {
//                           _selectedConsumption = value;
//                           _updateDisplayedData();
//                         },
//                       )),
//                       const SizedBox(width: 10),
//                       Expanded(
//                           child: _buildDropdown<String>(
//                         label: 'Measurement Status',
//                         items: _measurementStatuses,
//                         value: _selectedMeasurementStatus,
//                         onChanged: (value) {
//                           _selectedMeasurementStatus = value;
//                           _updateDisplayedData();
//                         },
//                       )),
//                       IconButton(
//                         onPressed: _exportToExcel,
//                         icon: Icon(Icons.download, color: primaryColor),
//                       ),
//                       if (!isHouseOwner) ...[
//                         const SizedBox(width: 10),
//                         IconButton(
//                           onPressed: _importFromCsv,
//                           icon: Icon(Icons.upload, color: primaryColor),
//                           tooltip: 'Import readings from Excel',
//                         ),
//                         const SizedBox(width: 10),
//                         ElevatedButton.icon(
//                           onPressed: () async {
//                             if (_selectedTown != null) {
//                               final town = await _firestore
//                                   .collection('town')
//                                   .doc(_selectedTown!['id'])
//                                   .get();
//                               showModalBottomSheet(
//                                 context: context,
//                                 isScrollControlled: true,
//                                 builder: (context) => HouseBillingCalculate(
//                                   townId: _selectedTown!['id'],
//                                   townName: _selectedTown!['name'],
//                                   townUnitPrice: town['unitPrice'].toString(),
//                                 ),
//                               );
//                             }
//                           },
//                           icon: const Icon(Icons.payment,
//                               size: 16, color: Colors.blue),
//                           label: const Text('Billing',
//                               style: TextStyle(color: Colors.white)),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20, vertical: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             elevation: 2,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           decoration: InputDecoration(
//                             labelText: "Search by House ID",
//                             border: const OutlineInputBorder(),
//                             labelStyle: TextStyle(
//                               color: primaryColor,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           onChanged: (value) =>
//                               setState(() => _searchQuery = value),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       _buildPaginationControls(),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   _buildDataTable(_months.indexOf(_selectedMonth!) + 1,
//                       int.parse(_selectedYear!)),
//                 ],
//               ),
//             ),
//     );
//   }

//   Future<void> showEditDialog(Map<String, dynamic> item) async {
//     TextEditingController lastReadingController =
//         TextEditingController(text: item['previousReading'].toString());
//     TextEditingController readingController =
//         TextEditingController(text: item['reading'].toString());
//     TextEditingController consumptionController =
//         TextEditingController(text: item['units'].toString().split(' ').first);
//     TextEditingController dateController = TextEditingController(
//         text: item['date'] == null ? null : dateFromTimestamp(item['date']));
//     TextEditingController consumptionDaysController =
//         TextEditingController(text: item['consumptionDays'].toString());
//     TextEditingController amountController = TextEditingController(
//         text: item['amount'].toString() == '-'
//             ? null
//             : item['amount'].toString());

//     String measurementStatus = item['measurementStatus'];

//     Future<void> _selectDate(BuildContext context) async {
//       final DateTime? picked = await showDatePicker(
//         context: context,
//         initialDate: DateTime.parse(dateController.text),
//         firstDate: DateTime(2000),
//         lastDate: DateTime(2101),
//       );
//       if (picked != null && picked != DateTime.parse(dateController.text)) {
//         dateController.text = "${picked.toLocal()}".split(' ')[0];
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Edit Reading'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Measurement Status',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: DropdownButtonFormField(
//                   items: ['pending', 'completed'].map((value) {
//                     return DropdownMenuItem(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                   onChanged: (_) {
//                     measurementStatus = _ as String;
//                     if (mounted) setState(() {});
//                   },
//                   value: measurementStatus,
//                   // decoration: InputDecoration(
//                   //   filled: true,
//                   //   fillColor: Colors.grey[200],
//                   // ),
//                 ),
//               ),
//               const SizedBox(height: 6),
//               const Text('Last Reading',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: lastReadingController,
//                   decoration:
//                       const InputDecoration(hintText: 'Enter last reading'),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text('Current Reading',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: readingController,
//                   decoration:
//                       const InputDecoration(hintText: 'Enter current reading'),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text('Consumption',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: consumptionController,
//                   decoration:
//                       const InputDecoration(hintText: 'Enter consumption'),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: dateController,
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     hintText: 'Select date',
//                     prefixIcon: Icon(Icons.calendar_today, color: borderColor),
//                   ),
//                   keyboardType: TextInputType.datetime,
//                   onTap: () async {
//                     await _selectDate(context);
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text('Consumption Days',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: consumptionDaysController,
//                   decoration:
//                       const InputDecoration(hintText: 'Enter consumption days'),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text('Amount \$',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Expanded(
//                 child: TextField(
//                   controller: amountController,
//                   decoration: InputDecoration(
//                     hintText: 'Enter amount',
//                     prefixIcon: Icon(Icons.attach_money, color: borderColor),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 pop(context);
//               },
//             ),
//             TextButton(
//               child: const Text('Save'),
//               onPressed: () async {
//                 unFocus(context);
//                 pop(context);
//                 await updateInvoice(
//                   item,
//                   measurementStatus,
//                   double.parse(lastReadingController.text),
//                   double.parse(readingController.text),
//                   double.parse(consumptionController.text),
//                   dateController.text,
//                   int.parse(consumptionDaysController.text),
//                   double.parse(
//                     amountController.text == '' ? '0.0' : amountController.text,
//                   ),
//                 );
//                 _loadData(reset: true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> updateInvoice(
//       Map<String, dynamic> item,
//       String measurementStatus,
//       double lastReading,
//       double reading,
//       double consumption,
//       String date,
//       int consumptionDaysController,
//       double amount) async {
//     String id = item['_readingId'];
//     try {
//       // Update the document in the reading collection
//       await firestore.collection('readings').doc(id).update({
//         'measurementStatus': measurementStatus,
//         'previousReading': lastReading,
//         'reading': reading,
//         'units': consumption,
//         'date': Timestamp.fromDate(DateTime.parse(date)),
//         'consumptionDays': consumptionDaysController,
//       });

//       House houseData =
//           await HouseServices.fetchByID(item['readingData']['_houseId']);

//       if (houseData.lastReading?['id'] == id) {
//         HouseServices.update(
//           item['readingData']['_houseId'],
//           {
//             'lastReading': {
//               'id': _generateReadingId(
//                 item['readingData']['_houseId'],
//                 DateTime.now().month,
//                 DateTime.now().year,
//               ),
//               'amount': amount,
//               'consumptionDays': consumptionDaysController,
//               'date': Timestamp.fromDate(DateTime.parse(date)),
//               'inspectorId': houseData.lastReading?['inspectorId'],
//               'meterImageURL': houseData.lastReading?['meterImageURL'],
//               'previousReading': houseData.lastReading?['previousReading'],
//               'previousUnits': houseData.lastReading?['previousUnits'],
//               'reading': reading,
//               'measurementStatus': measurementStatus,
//               'units': consumption,
//             },
//           },
//         );
//       }

//       final checkInvoice = await firestore
//           .collection('invoices')
//           .doc(_generateInvoiceId(item['readingData']['_houseId'],
//               DateTime.parse(date).month, DateTime.parse(date).year))
//           .get();

//       if (checkInvoice.exists) {
//         await firestore.collection('invoices').doc(item['_invoiceId']).update({
//           'amount': amount,
//         });
//       }
//       _loadData(reset: true);
//     } catch (e) {
//       debugPrint('Error updating invoice: $e');
//     }
//   }
// }
