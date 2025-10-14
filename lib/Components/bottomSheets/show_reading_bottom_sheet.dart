import 'dart:io';
import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/_services/reading_services.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/models/reading.dart';
import 'package:agua_med/models/town.dart';
import 'package:agua_med/providers/reading_bottom_sheet_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ShowReadingBottomSheet extends StatefulWidget {
  final House data;
  final dynamic newReading;
  final dynamic oldReadings;
  final dynamic imagePath;
  const ShowReadingBottomSheet({
    super.key,
    required this.data,
    required this.newReading,
    required this.oldReadings,
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
  var description = TextEditingController();

  String? comment;
  late House data;

  // Functions
  goAuth() {
    if (reading.text.isEmpty) {
      showToast(context,
          msg: 'ShowReadingBottomSheet.pleaseInputAReading'.tr());
    } else {
      double previousReading = 0;
      if (data.lastReading != null && data.lastReading!['reading'] != null) {
        previousReading =
            double.tryParse(data.lastReading!['reading'].toString()) ?? 0.00;
      }
      previousReading < double.parse(reading.text)
          ? submitReadingWithNavigation(
              context,
              image: context.read<ReadingBottomSheetProvider>().image,
              webImage: context.read<ReadingBottomSheetProvider>().webImage,
              inspectorUID: context.read<UserProvider>().user!.uid,
            )
          : discalimerBox(context);
    }
  }

  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
    );

    return File(result!.path);
  }

  Future<Uint8List?> compressWebImage(Uint8List webImage) async {
    return await FlutterImageCompress.compressWithList(
      webImage,
      quality: 80,
    );
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

  // For readings
  String _generateReadingId(String houseNumber, int month, int year) {
    return 'rd_${_generateSafeId(houseNumber, month, year)}';
  }

  Future<void> doSubmitReading(
      {required File? image,
      required Uint8List? webImage,
      required String inspectorUID}) async {
    try {
      Town? townData = await TownServices.fetchByID(data.townID);
      if (townData != null) {
        var perUnitPrice = double.parse(townData.unitPrice.toString());
        var currentReadingValue = double.tryParse(reading.text) ?? 0.00;

        double previousReadingValue = 0.00;
        DateTime previousReadingDate = DateTime.now();

        double units = 0.00;
        double previousUnit = 0.00;
        if (data.lastReading != null) {
          var lastReading = data.lastReading;
          previousReadingValue =
              double.tryParse(lastReading!['reading'].toString()) ?? 0.00;
          previousReadingDate = (lastReading['date'] as Timestamp).toDate();

          units = currentReadingValue - previousReadingValue;
          previousUnit =
              double.tryParse(lastReading['units'].toString()) ?? 0.00;
        } else {
          units = currentReadingValue;
        }

        var consumptionDays =
            DateTime.now().difference(previousReadingDate).inDays;
        var amount = units * perUnitPrice;

        String filePath = 'readings/${DateTime.now()}/$inspectorUID.jpg';
        TaskSnapshot uploadTask;

        if (kIsWeb) {
          var uploadedWebImage = await compressWebImage(webImage!);
          uploadTask = await _storage.ref(filePath).putData(uploadedWebImage!);
        } else {
          var uploadedMobileImage = await compressImage(image!);
          uploadTask =
              await _storage.ref(filePath).putFile(uploadedMobileImage);
        }

        String imgURL = await uploadTask.ref.getDownloadURL();

        ReadingServices.create(
          Reading(
            id: _generateReadingId(
              data.id,
              DateTime.now().month,
              DateTime.now().year,
            ),
            amount: amount,
            consumptionDays: consumptionDays,
            date: Timestamp.now(),
            houseId: data.id,
            inspectorId: inspectorUID,
            meterImageURL: imgURL,
            previousReading: previousReadingValue,
            previousUnits: previousUnit,
            reading: currentReadingValue,
            townId: data.townID,
            units: units,
            comment: comment,
            isDelete: false,
            readingStatus: comment == null ? 'approved' : 'pending',
            measurementStatus: 'completed',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
        );
        HouseServices.update(
          data.id,
          {
            'lastReading': {
              'id': _generateReadingId(
                data.id,
                DateTime.now().month,
                DateTime.now().year,
              ),
              'amount': amount,
              'consumptionDays': consumptionDays,
              'date': Timestamp.now(),
              'inspectorId': inspectorUID,
              'meterImageURL': imgURL,
              'previousReading': previousReadingValue,
              'previousUnits': previousUnit,
              'reading': currentReadingValue,
              'measurementStatus': 'completed',
              'units': units,
            },
          },
        );
        sendPushNotification();
      }
    } catch (e) {
      debugPrint("Error submitting reading: $e");
    }
  }

  void submitReadingWithNavigation(
    BuildContext context, {
    required File? image,
    required Uint8List? webImage,
    required String inspectorUID,
  }) {
    Future.microtask(() async {
      await doSubmitReading(
        image: image,
        webImage: webImage,
        inspectorUID: inspectorUID,
      );
    });
    Navigator.popUntil(context, (route) => route.isFirst);
    showToast(context, msg: "Reading submitted! Syncing in background...");
  }

  sendPushNotification() async {
    List<String> fcmTokens = [];
    try {
      var houseId = data.lastReading!['houseId'];
      var userDoc = await firestore
          .collection('user')
          .where('house.id', isEqualTo: houseId)
          .where('role', isEqualTo: 'HouseOwner')
          .get();

      if (userDoc.docs.isNotEmpty) {
        var userData = userDoc.docs.first.data();
        var adminDocs = await firestore
            .collection('user')
            .where('role', isEqualTo: 'Admin')
            .get();

        var townManagerDocs = await firestore
            .collection('user')
            .where('townId', isEqualTo: data.townID)
            .where('role', isEqualTo: 'Manager')
            .get();

        if (userData.containsKey('fcmToken') &&
            userData['fcmToken'] != null &&
            userData['fcmToken'].isNotEmpty) {
          fcmTokens.add(userData['fcmToken']);
        }

        for (var doc in adminDocs.docs) {
          if (doc.data().containsKey('fcmToken') &&
              doc['fcmToken'] != null &&
              doc['fcmToken'].isNotEmpty) {
            fcmTokens.add(doc['fcmToken']);
          }
        }

        for (var doc in townManagerDocs.docs) {
          if (doc.data().containsKey('fcmToken') &&
              doc['fcmToken'] != null &&
              doc['fcmToken'].isNotEmpty) {
            fcmTokens.add(doc['fcmToken']);
          }
        }
        var town = userData.containsKey('town') &&
                userData['town'] != null &&
                userData['town'].containsKey('name') &&
                userData['town']['name'].isNotEmpty
            ? userData['town']['name']
            : '-';
        var house = userData.containsKey('house') &&
                userData['house'] != null &&
                userData['house'].containsKey('name') &&
                userData['house']['name'].isNotEmpty
            ? userData['house']['name']
            : '-';
        var dio = Dio();
        for (var token in fcmTokens) {
          var response = await dio.post(
            'https://app-y5dnvohq3q-uc.a.run.app/send-notification',
            data: {
              'fcmToken': token,
              'title': 'ShowReadingBottomSheet.newReading'.tr(),
              'message': 'ShowReadingBottomSheet.readingHasBeenRecorded'
                  .tr(namedArgs: {'house': house, 'town': town}),
            },
          );
          if (response.statusCode == 200) {
            showToast(context,
                msg:
                    'ShowReadingBottomSheet.notificationSentSuccessfully'.tr());
          } else {
            showToast(context,
                msg: 'ShowReadingBottomSheet.failedToSendNotification'.tr());
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<Uint8List> _networkImageToUint8List(String imageUrl) async {
    final response = await Dio()
        .get(imageUrl, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data);
  }

  Future<Locale?> discalimerBox(
    BuildContext context,
  ) async {
    return await showDialog<Locale>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: primaryColor,
              insetPadding: EdgeInsets.zero,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * .38,
                width: MediaQuery.of(context).size.height * .38,
                child: Column(
                  children: [
                    Text(
                      'ShowReadingBottomSheet.lessConsumptionPopup'.tr(),
                      style: TextStyle(color: whiteColor),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: description,
                        decoration: InputDecoration(
                          fillColor: whiteColor,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          isDense: true,
                        ),
                        minLines: 4, // Minimum height of 1 line
                        maxLines:
                            4, // Expands up to 4 lines // Expands as needed
                        keyboardType:
                            TextInputType.multiline, // Allows multi-line input
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(13)),
                            child: TextButton(
                                onPressed: () {
                                  comment = description.text;
                                  description.clear();
                                  Navigator.pop(context);
                                  submitReadingWithNavigation(
                                    context,
                                    image: context
                                        .read<ReadingBottomSheetProvider>()
                                        .image,
                                    webImage: context
                                        .read<ReadingBottomSheetProvider>()
                                        .webImage,
                                    inspectorUID:
                                        context.read<UserProvider>().user!.uid,
                                  );
                                },
                                child: Text(
                                  'userRegistrationScreen.confirm'.tr(),
                                  style: TextStyle(color: blackColor),
                                )),
                          ),
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(13)),
                            child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'userRegistrationScreen.cancel'.tr(),
                                  style: TextStyle(color: blackColor),
                                )),
                          ),
                        ],
                      ),
                    )

                    // TextButton(onPressed: (){}, child: Text('userRegistrationScreen.cancel'.tr(),style: TextStyle(color: blackColor),))
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    var provider = context.read<ReadingBottomSheetProvider>();
    data = widget.data;
    reading.text = widget.newReading;
    if (kIsWeb) {
      provider.setWebImage(await _networkImageToUint8List(widget.imagePath));
    } else {
      provider.setImage(File(widget.imagePath));
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
        body: Consumer<ReadingBottomSheetProvider>(
          builder: (context, provider, child) {
            return GestureDetector(
              onTap: () => unFocus(context),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kIsWeb)
                      provider.webImage != null
                          ? SizedBox(
                              height: 400,
                              width: double.infinity,
                              child: Image.memory(
                                provider.webImage!,
                                fit: BoxFit.fitWidth,
                              ),
                            )
                          : Text('ShowReadingBottomSheet.noImageCaptured'.tr())
                    else
                      provider.image != null && provider.image!.path.isNotEmpty
                          ? SizedBox(
                              height: 400,
                              width: double.infinity,
                              child: Image.file(
                                provider.image!,
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: reading,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              DecimalInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText:
                                  'ShowReadingBottomSheet.enterTheReading'.tr(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'InvoiceScreen.previousReading'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: TextEditingController(
                                text: widget.oldReadings.toString()),
                            readOnly: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              DecimalInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText:
                                  'ShowReadingBottomSheet.enterTheReading'.tr(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Button(
                            text: 'ShowReadingBottomSheet.submit'.tr(),
                            onPressed:
                                // () {
                                //   discalimerBox(context);
                                // },
                                () => goAuth(),
                            width: double.infinity,
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Allow empty input
    if (text.isEmpty) return newValue;

    // If input matches valid pattern (integer or decimal with up to 2 places), allow it
    if (RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) {
      return newValue;
    }

    // Otherwise, return old value (prevents extra decimal places)
    return oldValue;
  }
}
