import 'package:agua_med/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BillingCalculateProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _buttonHover = false;
  bool _byHouseUnits = false;
  bool _byConsumptionAverage = false;
  List<Map<String, dynamic>> _pendingHouses = [];
  bool billingCompleted = false;

  bool get isLoading => _isLoading;
  bool get buttonHover => _buttonHover;
  bool get byHouseUnits => _byHouseUnits;
  bool get byConsumptionAverage => _byConsumptionAverage;
  List<Map<String, dynamic>> get pendingHouses => _pendingHouses;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void setButtonHover(bool value) {
    _buttonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setByHouseUnits(bool value) {
    _byHouseUnits = value;
    notifyListeners();
  }

  void setByConsumptionAverage(bool value) {
    _byConsumptionAverage = value;
    notifyListeners();
  }

  String _generateSafeId(String houseNumber, int month, int year) {
    // Handle null/empty/N/A cases
    if (houseNumber.isEmpty || houseNumber == 'N/A') {
      return 'default_${month.toString().padLeft(2, '0')}_$year';
    }

    // Basic sanitization
    var safeId = houseNumber
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_') // Replace special chars
        .replaceAll(RegExp(r'_+'), '_'); // Collapse multiple underscores

    // Ensure non-empty and limit length safely
    safeId = safeId.isEmpty ? 'house' : safeId;
    safeId = safeId.substring(0, safeId.length > 20 ? 20 : safeId.length);

    return '${safeId}_${month.toString().padLeft(2, '0')}_$year';
  }

// For invoices
  String _generateInvoiceId(String houseNumber, int month, int year) {
    return 'inv_${_generateSafeId(houseNumber, month, year)}';
  }

  Future<void> checkPendingReadings(String townId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final housesSnapshot = await firestore
          .collection('house')
          .where('townID', isEqualTo: townId)
          .where('isDelete', isEqualTo: false)
          .get();

      _pendingHouses = [];
      bool allBillingClosed = true;

      for (final house in housesSnapshot.docs) {
        final readingsSnapshot = await firestore
            .collection('readings')
            .where('houseId', isEqualTo: house.id)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (readingsSnapshot.docs.isEmpty) {
          _pendingHouses.add({
            'id': house.id,
            'name': house.data()['name'] ?? 'Unnamed House',
            'status': 'No readings',
          });
          allBillingClosed = false;
        } else {
          final lastReading = readingsSnapshot.docs.first;
          final readingData = lastReading.data();
          final readingDate = readingData['date'].toDate();

          if (readingDate.month != currentMonth ||
              readingDate.year != currentYear) {
            _pendingHouses.add({
              'id': house.id,
              'name': house.data()['name'] ?? 'Unnamed House',
              'status': 'Reading outdated',
            });
            allBillingClosed = false;
          }

          // Check billing status
          if (readingData['billingStatus'] != 'closed') {
            allBillingClosed = false;
          }
        }
      }

      billingCompleted = allBillingClosed;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error checking pending readings: $e');
    }
  }

  Future<void> calculateBillingInvoices({
    required BuildContext context,
    required String townId,
    required double unitPrice,
    required double consumtionBasedAmount,
    required double houseBasedAmount,
    required double fixedAmount,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final housesSnapshot = await firestore
          .collection('house')
          .where('townID', isEqualTo: townId)
          .where('isDelete', isEqualTo: false)
          .get();

      int pendingCount = 0;
      final houses = housesSnapshot.docs;
      final numberOfHouses = houses.length;

      double totalConsumption = 0.0;
      Map<String, Map<String, dynamic>> houseReadings = {};
      List<DocumentReference> readingDocsToUpdate = [];

      // Check readings and calculate total consumption
      for (final house in houses) {
        final readingsSnapshot = await firestore
            .collection('readings')
            .where('houseId', isEqualTo: house.id)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (readingsSnapshot.docs.isEmpty) {
          pendingCount++;
          continue;
        }

        final lastReading = readingsSnapshot.docs.first;
        final readingData = lastReading.data();
        final readingDate = readingData['date'].toDate();

        if (readingDate.month != currentMonth ||
            readingDate.year != currentYear) {
          pendingCount++;
        } else {
          final consumption = readingData['units'] ?? 0.0;
          totalConsumption += consumption;
          houseReadings[house.id] = {
            'data': readingData,
            'consumption': consumption,
            'readingDoc':
                lastReading.reference, // Store reference to update later
          };
          readingDocsToUpdate.add(lastReading.reference);
        }
      }

      if (pendingCount == 0 && totalConsumption > 0) {
        // First update all reading documents to mark them as billed
        final batch = firestore.batch();
        for (final docRef in readingDocsToUpdate) {
          batch.update(docRef, {'billingStatus': 'closed'});
        }
        await batch.commit();

        // Then create the invoices
        for (final house in houses) {
          final readingInfo = houseReadings[house.id];
          if (readingInfo != null) {
            final houseConsumption = readingInfo['consumption'] as double;
            final readingData = readingInfo['data'] as Map<String, dynamic>;

            double bill;

            if (_byConsumptionAverage) {
              bill = consumtionBasedAmount *
                      (houseConsumption / totalConsumption) +
                  (houseBasedAmount / numberOfHouses) +
                  fixedAmount;
            } else {
              bill = (unitPrice * houseConsumption) +
                  (houseBasedAmount / numberOfHouses) +
                  fixedAmount;
            }

            final invoiceData = {
              'id': _generateInvoiceId(house.id, currentMonth, currentYear),
              'houseId': house.id,
              'houseName': house.data()['name'] ?? 'Unnamed House',
              'townId': townId,
              'basedOn': _byConsumptionAverage ? 'Consumptions' : 'Units',
              'unitPrice': unitPrice,
              'consumtionBasedAmount': consumtionBasedAmount,
              'houseBasedAmount': houseBasedAmount,
              'fixedAmount': fixedAmount,
              'amount': bill,
              'month': currentMonth,
              'year': currentYear,
              'createdAt': DateTime.now(),
              'reading': readingData,
            };

            await firestore
                .collection('invoices')
                .doc(_generateInvoiceId(house.id, currentMonth, currentYear))
                .set(invoiceData);
          }
        }

        showToast(context, msg: 'Billing calculated successfully!');
      } else {
        await checkPendingReadings(townId);
        return;
      }

      _isLoading = false;
      notifyListeners();
      Navigator.pop(context);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error calculating billing: $e');
      showToast(context, msg: 'Error calculating billing: $e');
    }
  }

  // Add to BillingCalculateProvider class
  Future<void> updateHouseBilling({
    required String basedOn,
    required BuildContext context,
    required String invoiceId,
    required double consumtionBasedAmount,
    required double houseBasedAmount,
    required double fixedAmount,
    required double unitPrice,
    required double consumptions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await firestore.collection('invoices').doc(invoiceId).update({
        'consumtionBasedAmount': consumtionBasedAmount,
        'houseBasedAmount': houseBasedAmount,
        'fixedAmount': fixedAmount,
        'unitPrice': unitPrice,
        'amount': basedOn == 'Consumptions'
            ? consumtionBasedAmount + houseBasedAmount + fixedAmount
            : (consumptions * unitPrice) + houseBasedAmount + fixedAmount,
        'updatedAt': DateTime.now(),
      });

      showToast(context, msg: 'Billing updated successfully!');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating billing: $e');
      showToast(context, msg: 'Error updating billing: $e');
    }
  }
}
