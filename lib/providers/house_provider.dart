import 'dart:convert';
import 'dart:io';

import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/house.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart'; // For

class HouseProvider extends ChangeNotifier {
  String? _query;
  bool _addButtonHover = false;
  bool _searchButtonHover = false;
  bool _exportButtonHover = false;

  String? get query => _query;
  bool get addButtonHover => _addButtonHover;
  bool get searchButtonHover => _searchButtonHover;
  bool get exportButtonHover => _exportButtonHover;

  void setQuery(String? query) {
    _query = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setAddButtonHover(bool value) {
    _addButtonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setSearchButtonHover(bool value) {
    _searchButtonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearQuery() {
    _query = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Uint8List? getFileBytes(PlatformFile file) {
    if (kIsWeb) {
      return file.bytes;
    } else {
      try {
        return File(file.path!).readAsBytesSync();
      } catch (e) {
        return null;
      }
    }
  }

  Future<void> importHousesFromCsv(BuildContext context, String townId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Must be true for web
      );

      if (result == null || result.files.first.bytes == null) {
        showToast(context, msg: 'No file selected or unreadable file.');
        return;
      }

      // Read CSV file as string
      Uint8List fileBytes = result.files.first.bytes!;
      String csvString = utf8.decode(fileBytes);

      // Parse CSV
      List<List<dynamic>> csvData =
          const CsvToListConverter().convert(csvString);

      if (csvData.length <= 1) {
        showToast(context, msg: 'CSV must contain at least one data row.');
        return;
      }

      List<Map<String, dynamic>> housesToAdd = [];

      // Assume headers: name, cohabitants, meterNumber, houseType
      for (var row in csvData.skip(1)) {
        if (row.length < 5) continue;

        try {
          housesToAdd.add({
            'name': row[0].toString(),
            'cohabitants': int.tryParse(row[2].toString()) ?? 0,
            'meterNumber': row[3].toString(),
            'houseType': row[4].toString(),
          });
        } catch (e) {
          debugPrint('Error parsing row: $e');
        }
      }

      if (housesToAdd.isEmpty) {
        showToast(context, msg: 'No valid house data found in the CSV file');
        return;
      }

      // Show confirmation
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Import ${housesToAdd.length} houses?'),
              content: Text(
                  'Are you sure you want to import ${housesToAdd.length} houses?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Import'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      showLoader(context, 'Importing ${housesToAdd.length} houses...');

      int successCount = 0;
      for (var houseData in housesToAdd) {
        try {
          await HouseServices.create(
            context,
            House(
              id: '',
              name: houseData['name'],
              townID: townId,
              cohabitants: houseData['cohabitants'],
              meterNumber: houseData['meterNumber'],
              isDelete: false,
              lastReading: null,
              houseType: houseData['houseType'],
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            ),
          );
          successCount++;
        } catch (e) {
          debugPrint('Error creating house: $e');
        }
      }

      pop(context); // Close loader

      showToast(
        context,
        msg:
            'Successfully imported $successCount of ${housesToAdd.length} houses',
        duration: 3,
      );
    } catch (e) {
      pop(context);
      showToast(context, msg: 'Error importing CSV: ${e.toString()}');
    }
  }

  void setExportButtonHover(bool value) {
    _exportButtonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> exportHousesToExcel(BuildContext context, String townId) async {
    try {
      showLoader(context, 'Preparing export...');

      // Get all houses for this town
      final houses = await HouseServices.fetchAllByTown(townId);

      if (houses.isEmpty) {
        pop(context);
        showToast(context, msg: 'No houses to export');
        return;
      }

      // Create a new Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Houses'];

      excel.delete('Sheet1');

      // Add headers
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('House Name'),
        TextCellValue('House State'),
        TextCellValue('Cohabitants'),
        TextCellValue('Meter Number'),
        TextCellValue('House Type'),
      ]);

      // Add data rows
      for (final house in houses) {
        sheet.appendRow([
          TextCellValue(house.id),
          TextCellValue(house.name),
          house.cohabitants == null
              ? TextCellValue('')
              : IntCellValue(house.cohabitants!),
          TextCellValue(house.meterNumber),
          TextCellValue(house.houseType ?? ''),
        ]);
      }

      // Save the Excel file
      final dateString =
          DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-');
      final fileName = 'Houses_Export_$dateString.xlsx';

      final bytes = excel.save(fileName: fileName);
      if (bytes == null) {
        pop(context);
        showToast(context, msg: 'Error generating Excel file');
        return;
      }

      pop(context);
      showToast(context, msg: 'Exported ${houses.length} houses');
    } catch (e) {
      pop(context);
      showToast(context, msg: 'Error exporting houses: ${e.toString()}');
      debugPrint('Export error: $e');
    }
  }
}
