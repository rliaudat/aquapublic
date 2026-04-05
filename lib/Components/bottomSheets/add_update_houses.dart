import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/models/house.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../loading.dart';
import '../../theme.dart';
import '../Reuseable.dart';

class AddUpdateHouses extends StatefulWidget {
  final String? houseId;
  final String? houseName;
  final int? cohabitants;
  final String? meterNumber;
  final String? houseType;
  final String townId;
  final String townName;

  const AddUpdateHouses({
    super.key,
    this.houseId,
    this.houseName,
    this.cohabitants,
    this.meterNumber,
    this.houseType,
    required this.townId,
    required this.townName,
  });

  @override
  State<AddUpdateHouses> createState() => _AddUpdateHousesState();
}

class _AddUpdateHousesState extends State<AddUpdateHouses> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var town = TextEditingController();
  var house = TextEditingController();
  String? cohabitants;
  var meterNumber = TextEditingController();
  String? houseType;
  bool addHover = false;

  goAuth() {
    if (house.text.isEmpty) {
      showToast(context, msg: 'AddUpdateHouses.pleaseEnterHouseName'.tr());
    } else if (meterNumber.text.isEmpty) {
      showToast(context, msg: 'AddUpdateHouses.pleaseEnterMeterNumber'.tr());
    } else {
      if (widget.houseId != null) {
        doUpdate();
      } else {
        doCreate();
      }
    }
  }

  doUpdate() {
    var obj = {
      'name': house.text,
      'cohabitants': cohabitants == null ? null : int.tryParse(cohabitants!),
      'meterNumber': meterNumber.text,
      'houseType': houseType,
    };
    try {
      showLoader(context, 'AddUpdateHouses.justAMoment'.tr());
      HouseServices.update(widget.houseId!, obj);
      pop(context);
      pop(context);
      showToast(context, msg: 'AddUpdateHouses.houseUpdatedSuccessfully'.tr());
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  doCreate() async {
    try {
      showLoader(context, 'AddUpdateHouses.justAMoment'.tr());
      HouseServices.create(
        context,
        House(
          id: '',
          name: house.text,
          townID: widget.townId,
          isDelete: false,
          lastReading: null,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ),
      );
      pop(context);
      pop(context);
      showToast(context, msg: 'AddUpdateHouses.houseAddedSuccessfully'.tr());
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  // addOrUpdateHouse() async {
  //   if (house.text.isNotEmpty) {
  //     final townQuery = await FirebaseFirestore.instance
  //         .collection('towns')
  //         .where('name', isEqualTo: town.text)
  //         .get();

  //     if (townQuery.docs.isNotEmpty) {
  //       final townDoc = townQuery.docs.first;

  //       final houseRef = widget.houseId != null
  //           ? townDoc.reference.collection('houses').doc(widget.houseId)
  //           : townDoc.reference.collection('houses').doc();

  //       await houseRef.set({
  //         'name': house.text,
  //         'createdAt': FieldValue.serverTimestamp(),
  //         'isDelete': false
  //       });

  //       pop(context);
  //       showToast(context,
  //           msg: 'AddUpdateHouses.houseAndReadingAddedUpdatedSuccessfully'.tr(),
  //           duration: 3);
  //     }
  //   }
  // }

  @override
  void initState() {
    town.text = widget.townName;
    if (widget.houseName != null) {
      house.text = widget.houseName!;
      cohabitants = widget.cohabitants?.toString();
      meterNumber.text = widget.meterNumber!;
      houseType = widget.houseType;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
              ),
              color: greyColor,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: p).copyWith(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.houseId == null
                            ? 'AddUpdateHouses.addHouse'.tr()
                            : 'AddUpdateHouses.editHouse'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_outlined,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AddUpdateHouses.town'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: town,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '',
                      prefixIcon: Icon(Icons.location_city, color: borderColor),
                    ),
                  ),
                  SizedBox(height: p),
                  Text(
                    'AddUpdateHouses.house'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: house,
                    decoration: InputDecoration(
                      hintText: 'AddUpdateHouses.enterHouseName'.tr(),
                      prefixIcon: Icon(Icons.home, color: borderColor),
                    ),
                  ),
                  SizedBox(height: p),
                  Text(
                    'AddUpdateHouses.cohabitants'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField(
                    items: ['2', '3', '4', '5', '6'].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (_) {
                      cohabitants = _;
                      if (mounted) setState(() {});
                    },
                    value: cohabitants,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  SizedBox(height: p),
                  Text(
                    'AddUpdateHouses.meterNumber'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: meterNumber,
                    decoration: InputDecoration(
                      hintText: 'AddUpdateHouses.enterMeterNumber'.tr(),
                      prefixIcon: Icon(Icons.home, color: borderColor),
                    ),
                  ),
                  SizedBox(height: p),
                  Text(
                    'AddUpdateHouses.houseType'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField(
                    items: ['Living', 'Weekend', ' Under Construction', 'Lot']
                        .map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (_) {
                      houseType = _;
                      if (mounted) setState(() {});
                    },
                    value: houseType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => addHover = true),
                    onExit: (_) => setState(() => addHover = false),
                    child: Button(
                      color: addHover ? primaryColor : secondaryColor,
                      height: 50,
                      width: double.infinity,
                      text: widget.houseId == null
                          ? 'AddUpdateHouses.add'.tr()
                          : 'AddUpdateHouses.update'.tr(),
                      onPressed: () => goAuth(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
