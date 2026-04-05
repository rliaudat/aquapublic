import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/models/town.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../loading.dart';
import '../../theme.dart';
import '../Reuseable.dart';

class AddUpdateTown extends StatefulWidget {
  final String? townId;
  final String? townName;
  final String? townUnitPrice;
  const AddUpdateTown(
      {super.key, this.townId, this.townName, this.townUnitPrice});

  @override
  State<AddUpdateTown> createState() => _AddUpdateTownState();
}

class _AddUpdateTownState extends State<AddUpdateTown> {
  bool townHover = false;
  var townController = TextEditingController();
  var townUnitPriceController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  addTown() async {
    String? townId = widget.townId;

    if (townController.text.isEmpty || townUnitPriceController.text.isEmpty) {
      if (townController.text.isEmpty) {
        showToast(context,
            msg: 'AddUpdateTown.pleaseEnterTownName'.tr(), duration: 3);
      } else if (townUnitPriceController.text.isEmpty) {
        showToast(context,
            msg: 'AddUpdateTown.pleaseEnterPerUnitPrice'.tr(), duration: 3);
      }
    } else {
      if (townId != null) {
        TownServices.update(
          context,
          townId,
          {
            'name': townController.text,
            'unitPrice': double.parse(townUnitPriceController.text),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
        pop(context);
        townController.clear();
        showToast(context,
            msg: 'AddUpdateTown.townUpdatedSuccessfully'.tr(), duration: 3);
      } else {
        TownServices.create(
          context,
          Town(
            id: '',
            name: townController.text,
            unitPrice: double.parse(townUnitPriceController.text),
            isDelete: false,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
        );
        pop(context);
        townController.clear();
        showToast(context,
            msg: 'AddUpdateTown.townAddedSuccessfully'.tr(), duration: 3);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    townController = TextEditingController(text: widget.townName ?? '');
    townUnitPriceController =
        TextEditingController(text: widget.townUnitPrice ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: MediaQuery.of(context).viewInsets,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            topLeft: Radius.circular(30),
          ),
          color: greyColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AddUpdateTown.addTown'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => pop(context),
                    child: Icon(
                      Icons.close_outlined,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: townController,
                decoration: InputDecoration(
                  hintText: 'AddUpdateTown.addTownName'.tr(),
                  prefixIcon: Icon(Icons.home_work, color: borderColor),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: townUnitPriceController,
                decoration: InputDecoration(
                  hintText: 'AddUpdateTown.unitPriceM3'.tr(),
                  prefixIcon: Icon(Icons.electric_meter, color: borderColor),
                ),
              ),
              const SizedBox(height: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => townHover = true),
                onExit: (_) => setState(() => townHover = false),
                child: Button(
                    color: townHover ? primaryColor : secondaryColor,
                    height: 45,
                    width: width(context),
                    text: widget.townId != null
                        ? 'AddUpdateTown.updateTown'.tr()
                        : 'AddUpdateTown.addTown'.tr(),
                    fontSize: 14,
                    onPressed: () {
                      addTown();
                    }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
