import 'package:agua_med/_services/reading_services.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/models/reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HouseServices {
  static final _houseCollection = FirebaseFirestore.instance.collection(
    'house',
  );

  static Future<void> create(BuildContext context, House house) async {
    await _houseCollection
        .add(
      house.toMap(),
    )
        .then((value) {
      _houseCollection.doc(value.id).update({'id': value.id});
    }).catchError((error) {
      String errorMessage = "Something went wrong. Please try again.";

      if (error is FirebaseException && error.code == 'unavailable') {
        errorMessage =
            "You're offline. Data will sync once you're back online.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  static void update(String id, Map<String, dynamic> data) {
    _houseCollection.doc(id).update(data);
  }

  static Future<House> fetchByID(String id) async {
    return House.fromDoc(await _houseCollection.doc(id).get());
  }

  static Future<List<House>> fetchAllByTown(String townID) async {
    try {
      List<House> houses = [];
      QuerySnapshot snapshot = await _houseCollection
          .where('townID', isEqualTo: townID)
          .where('isDelete', isEqualTo: false)
          .orderBy('createdAt')
          .get();
      for (var houseDoc in snapshot.docs) {
        houses.add(House.fromDoc(houseDoc));
      }
      return houses;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }

  static Future<List<House>> fetchAllByTownWithDelete(String townID) async {
    try {
      List<House> houses = [];
      QuerySnapshot snapshot = await _houseCollection
          .where('townID', isEqualTo: townID)
          .orderBy('createdAt')
          .get();
      for (var houseDoc in snapshot.docs) {
        houses.add(House.fromDoc(houseDoc));
      }
      return houses;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }

  static Stream<List<House>> houseStream(String townID) {
    return _houseCollection
        .where('townID', isEqualTo: townID)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return House.fromDoc(doc);
          }).toList(),
        );
  }

  static Stream<List<House>> houseReadingStream(String townID) {
    return _houseCollection
        .where('townID', isEqualTo: townID)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return House.fromDoc(doc);
          }).toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> houseWithAllPastReadingStream(
      List<dynamic> townIDs) {
    return _houseCollection
        .where('townID', whereIn: townIDs)
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> houseWithReadings = [];
      List<House> houses = snapshot.docs.map((doc) {
        return House.fromDoc(doc);
      }).toList();
      for (House itr in houses) {
        List<Reading> readings =
            await ReadingServices.fetchLastTwelveReadings(itr.id);
        houseWithReadings.add({'house': itr, 'readings': readings});
      }
      return houseWithReadings;
    });
  }
}
