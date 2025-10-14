import 'package:agua_med/models/reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingServices {
  static final _readingCollection = FirebaseFirestore.instance.collection(
    'readings',
  );

  static String _generateSafeId(String houseNumber, int month, int year) {
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

  // For readings
  static String _generateReadingId(String houseNumber, int month, int year) {
    return 'rd_${_generateSafeId(houseNumber, month, year)}';
  }

  static void create(Reading reading) {
    _readingCollection
        .doc(_generateReadingId(reading.houseId, reading.date.toDate().month,
            reading.date.toDate().year))
        .set(reading
            .copyWith(
                id: _generateReadingId(reading.houseId,
                    reading.date.toDate().month, reading.date.toDate().year))
            .toMap());
  }

  static Future<DocumentSnapshot?> fetchByID(
      String houseID, int month, int year) async {
    final reading = await _readingCollection
        .doc(_generateReadingId(houseID, month, year))
        .get();
    if (reading.exists) {
      return reading;
    } else {
      return null;
    }
  }

  static Future<List<Reading>> fetchLastTwelveReadings(String houseID) async {
    try {
      List<Reading> readings = [];
      QuerySnapshot snapshot = await _readingCollection
          .where('houseId', isEqualTo: houseID)
          .where('isDelete', isEqualTo: false)
          .limit(12)
          .orderBy('createdAt', descending: true)
          .get();
      for (var readingDoc in snapshot.docs) {
        readings.add(Reading.fromDoc(readingDoc));
      }
      return readings;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }
}
