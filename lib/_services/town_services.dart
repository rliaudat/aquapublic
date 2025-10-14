import 'package:agua_med/models/town.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TownServices {
  static final _townCollection = FirebaseFirestore.instance.collection(
    'town',
  );

  static void create(BuildContext context, Town town) {
    _townCollection
        .add(
      town.toMap(),
    )
        .then((value) {
      _townCollection.doc(value.id).update({'id': value.id});
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

  static void update(
      BuildContext context, String id, Map<String, dynamic> data) {
    _townCollection.doc(id).update(data).catchError((error) {
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

  static Future<List<Town>> fetchAll() async {
    try {
      List<Town> towns = [];
      QuerySnapshot snapshot = await _townCollection
          .where('isDelete', isEqualTo: false)
          .orderBy('createdAt')
          .get();
      for (var townDoc in snapshot.docs) {
        towns.add(Town.fromDoc(townDoc));
      }
      return towns;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }

  static Future<Town?> fetchByID(String id) async {
    try {
      DocumentSnapshot snapshot = await _townCollection.doc(id).get();
      if (snapshot.exists) {
        return Town.fromDoc(snapshot);
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }

  static Future<List<Town>> fetchAllWithDelete() async {
    try {
      List<Town> towns = [];
      QuerySnapshot snapshot = await _townCollection.orderBy('createdAt').get();
      for (var townDoc in snapshot.docs) {
        towns.add(Town.fromDoc(townDoc));
      }
      return towns;
    } on FirebaseException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('unknown');
    }
  }

  static Stream<List<Town>> townStream() {
    return _townCollection
        .where('isDelete', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Town.fromDoc(doc);
          }).toList(),
        );
  }
}
