import 'dart:io';
import 'package:agua_med/_helpers/global.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:easy_localization/easy_localization.dart';

class ShowReadingBottomSheet extends StatefulWidget {
  final dynamic data;
  final dynamic newReading;
  final dynamic imagePath;
  const ShowReadingBottomSheet({
    super.key,
    required this.data,
    required this.newReading,
    required this.imagePath,
  });

  @override
  State<ShowReadingBottomSheet> createState() => _ShowReadingBottomSheetState();
}

class _ShowReadingBottomSheetState extends State<ShowReadingBottomSheet> {
  // Variables
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var reading = TextEditingController();
  dynamic data;
  File? image;
  Uint8List? webImage;

  // Functions
  goAuth() {
    if (reading.text.isEmpty) {
      showToast(context, msg: 'ShowReadingBottomSheet.pleaseInputAReading'.tr());
    } else {
      int previousReading = data['lastReading'] != null && data['lastReading']['reading'] != null && data['lastReading']['reading'].isNotEmpty ? int.parse(data['lastReading']['reading']) : 0;
      previousReading < int.parse(reading.text) ? doSubmitReading() : showToast(context, msg: 'ShowReadingBottomSheet.readingShouldBeGreaterThanThePreviousReading'.tr());
    }
  }

  doSubmitReading() async {
    try {
      showLoader(context, 'ShowReadingBottomSheet.justAMoment'.tr());

      var townId = selectedTown['id'];
      var townData = await firestore.collection('towns').doc(townId).get();
      var perUnitPrice = int.parse(townData['unitPrice']);
      var currentReadingValue = int.parse(reading.text);

      var previousReadingValue = 0;
      var previousReadingDate = DateTime.now();

      var units = 0;
      var previousUnit = 0;
      if (data['lastReading'] != null) {
        var lastReading = data['lastReading'];
        previousReadingValue = int.parse(lastReading['reading']);
        previousReadingDate = (lastReading['date'] as Timestamp).toDate();

        // Calculate units as the difference between the current and previous readings
        units = currentReadingValue - previousReadingValue;

        // Calculate previous unit as the previous reading value
        previousUnit = lastReading['units'];
      }

      // Calculate consumption days as the difference between current and previous reading dates
      var consumptionDays = DateTime.now().difference(previousReadingDate).inDays;

      // Calculate the amount based on units and per unit price ($3 per unit)
      var amount = units * perUnitPrice;

      // Set the previous unit (this can be the unit value from the previous reading)

      String filePath = 'readings/${DateTime.now()}/${userSD['id']}.jpg';
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await _storage.ref(filePath).putData(webImage!);
      } else {
        uploadTask = await _storage.ref(filePath).putFile(image!);
      }
      String imgURL = await uploadTask.ref.getDownloadURL();
      // Create the reading object
      var obj = {
        'meterImageUrl': imgURL,
        'amount': amount,
        'reading': reading.text,
        'units': units,
        'previousUnit': previousUnit,
        'previousReading': previousReadingValue,
        'consumptionDays': consumptionDays,
        'townId': townId,
        'houseId': data['id'],
        'inspectorId': userSD['id'],
        'date': FieldValue.serverTimestamp(),
      };

      // Generate a new document reference with a unique ID
      var newDocRef = firestore.collection('reading').doc();

      // Submit the reading to Firestore with the same document ID
      await newDocRef.set(obj);
      await firestore.collection('towns').doc(townId).collection('houses').doc(data['id']).collection('reading').doc(newDocRef.id).set(obj);
      sendPushNotification();
      pop(context);
      Navigator.popUntil(context, (route) => route.isFirst);
      showToast(context, msg: 'ShowReadingBottomSheet.readingSuccessfullySubmitted'.tr());
    } catch (e) {
      showToast(context, msg: 'ShowReadingBottomSheet.failedToSubmitReading'.tr(args: [e.toString()]));
      pop(context);
    }
  }

  sendPushNotification() async {
    List<String> fcmTokens = [];
    try {
      // var houseId = data['lastReading']['houseId'];
      var houseId = 'X2mFRyTLZYadT6JK9J2w';
      var userDoc = await firestore.collection('users').where('house.id', isEqualTo: houseId).where('role', isEqualTo: 'HouseOwner').get();

      if (userDoc.docs.isNotEmpty) {
        var userData = userDoc.docs.first.data();
        var adminDocs = await firestore.collection('users').where('role', isEqualTo: 'Admin').get();

        var townManagerDocs = await firestore.collection('users').where('townId', isEqualTo: data['townId']).where('role', isEqualTo: 'Manager').get();

        if (userData.containsKey('fcm_token') && userData['fcm_token'] != null && userData['fcm_token'].isNotEmpty) fcmTokens.add(userData['fcm_token']);

        for (var doc in adminDocs.docs) {
          if (doc.data().containsKey('fcm_token') && doc['fcm_token'] != null && doc['fcm_token'].isNotEmpty) fcmTokens.add(doc['fcm_token']);
        }

        for (var doc in townManagerDocs.docs) {
          if (doc.data().containsKey('fcm_token') && doc['fcm_token'] != null && doc['fcm_token'].isNotEmpty) fcmTokens.add(doc['fcm_token']);
        }
        var town = userData.containsKey('town') && userData['town'] != null && userData['town'].containsKey('name') && userData['town']['name'].isNotEmpty ? userData['town']['name'] : '-';
        var house = userData.containsKey('house') && userData['house'] != null && userData['house'].containsKey('name') && userData['house']['name'].isNotEmpty ? userData['house']['name'] : '-';
        var dio = Dio();
        for (var token in fcmTokens) {
          var response = await dio.post(
            'https://app-y5dnvohq3q-uc.a.run.app/send-notification',
            data: {
              'fcm_token': token,
              'title': 'ShowReadingBottomSheet.newReading'.tr(),
              'message': 'ShowReadingBottomSheet.readingHasBeenRecorded'.tr(namedArgs: {'house': house, 'town': town}),
            },
          );
          if (response.statusCode == 200) {
            showToast(context, msg: 'ShowReadingBottomSheet.notificationSentSuccessfully'.tr());
          } else {
            showToast(context, msg: 'ShowReadingBottomSheet.failedToSendNotification'.tr());
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<Uint8List> _networkImageToUint8List(String imageUrl) async {
    final response = await Dio().get(imageUrl, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data);
  }

  void initState() {
    init();
    super.initState();
  }

  init() async {
    data = widget.data;
    reading.text = widget.newReading;
    if (kIsWeb) {
      webImage = await _networkImageToUint8List(widget.imagePath);
      if (mounted) setState(() {});
    } else {
      image = File(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('ShowReadingBottomSheet.capturedReading'.tr()),
          backgroundColor: primaryColor,
        ),
        body: GestureDetector(
          onTap: () => unFocus(context),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kIsWeb)
                  webImage != null
                      ? SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: Image.memory(
                            webImage!,
                            fit: BoxFit.fitWidth,
                          ),
                        )
                      : Text('ShowReadingBottomSheet.noImageCaptured'.tr())
                else
                  image != null && image!.path.isNotEmpty
                      ? SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: Image.file(
                            image!,
                            fit: BoxFit.fitWidth,
                          ),
                        )
                      : Text('ShowReadingBottomSheet.noImageCaptured'.tr()),
                Padding(
                  padding: EdgeInsets.all(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ShowReadingBottomSheet.reading'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: reading,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'ShowReadingBottomSheet.enterTheReading'.tr(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Button(
                        text: 'ShowReadingBottomSheet.submit'.tr(),
                        onPressed: () => goAuth(),
                        width: double.infinity,
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
