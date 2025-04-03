import 'package:agua_med/models/reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingServices {
  static final _readingCollection = FirebaseFirestore.instance.collection(
    'readings',
  );

  static void create(Reading reading) {
    _readingCollection
        .add(
      reading.toMap(),
    )
        .then((value) {
      _readingCollection.doc(value.id).update({'id': value.id});
    });
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
