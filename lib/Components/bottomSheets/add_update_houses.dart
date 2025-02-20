import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../loading.dart';
import '../../theme.dart';
import '../Reuseable.dart';

class AddUpdateHouses extends StatefulWidget {
  final String? houseId;
  final String? houseName;
  final String townId;
  final String townName;

  const AddUpdateHouses({
    super.key,
    this.houseId,
    this.houseName,
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
  bool addHover = false;

  goAuth() {
    if (house.text.isEmpty) {
      showToast(context, msg: 'AddUpdateHouses.pleaseEnterHouseName'.tr());
    } else {
      if (widget.houseId != null) {
        doUpdate();
      } else {
        doCreate();
      }
    }
  }

  doUpdate() {
    var obj = {'name': house.text};
    try {
      showLoader(context, 'AddUpdateHouses.justAMoment'.tr());
      firestore.collection('towns').doc(widget.townId).collection('houses').doc(widget.houseId).update(obj);
      pop(context);
      pop(context);
      showToast(context, msg: 'AddUpdateHouses.houseUpdatedSuccessfully'.tr());
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  doCreate() async {
    var obj = {'name': house.text, 'createdAt': FieldValue.serverTimestamp(), 'isDelete': false};
    try {
      showLoader(context, 'AddUpdateHouses.justAMoment'.tr());
      await firestore.collection('towns').doc(widget.townId).collection('houses').doc().set(obj);
      pop(context);
      pop(context);
      showToast(context, msg: 'AddUpdateHouses.houseAddedSuccessfully'.tr());
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  addOrUpdateHouse() async {
    if (house.text.isNotEmpty) {
      final townQuery = await FirebaseFirestore.instance.collection('towns').where('name', isEqualTo: town.text).get();

      if (townQuery.docs.isNotEmpty) {
        final townDoc = townQuery.docs.first;

        final houseRef = widget.houseId != null ? townDoc.reference.collection('houses').doc(widget.houseId) : townDoc.reference.collection('houses').doc();

        await houseRef.set({'name': house.text, 'createdAt': FieldValue.serverTimestamp(), 'isDelete': false});

        pop(context);
        showToast(context, msg: 'AddUpdateHouses.houseAndReadingAddedUpdatedSuccessfully'.tr(), duration: 3);
      }
    }
  }

  @override
  void initState() {
    town.text = widget.townName;
    if (widget.houseName != null) {
      house.text = widget.houseName!;
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
                        widget.houseId == null ? 'AddUpdateHouses.addHouse'.tr() : 'AddUpdateHouses.editHouse'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_outlined, color: Colors.black),
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
                  const SizedBox(height: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => addHover = true),
                    onExit: (_) => setState(() => addHover = false),
                    child: Button(
                      color: addHover ? primaryColor : secondaryColor,
                      height: 50,
                      width: double.infinity,
                      text: widget.houseId == null ? 'AddUpdateHouses.add'.tr() : 'AddUpdateHouses.update'.tr(),
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
