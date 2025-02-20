import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../theme.dart';

class InspectorFilterBottomSheet extends StatefulWidget {
  const InspectorFilterBottomSheet({super.key});

  @override
  State<InspectorFilterBottomSheet> createState() => _InspectorFilterBottomSheetState();
}

class _InspectorFilterBottomSheetState extends State<InspectorFilterBottomSheet> {
  DateTime? selectedDate;
  bool isSelected = true;
  TextEditingController townController = TextEditingController();
  List items = ['Town A', 'Town B', 'Town C', 'Town D', 'Town E', 'Town F'];
  List filteredItems = [];
  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();

  @override
  void dispose() {
    townController.dispose();
    super.dispose();
  }

  void showOverlay() {
    if (overlayEntry != null) return;
    double dropdownHeight;
    if (filteredItems.length == 1) {
      dropdownHeight = 40.0;
    } else if (filteredItems.length > 1) {
      dropdownHeight = 150.0;
    } else {
      dropdownHeight = 0.0;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width(context) * 0.93,
        child: CompositedTransformFollower(
          link: layerLink,
          offset: const Offset(0, 50),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: dropdownHeight,
              child: ListView(
                padding: EdgeInsets.zero,
                children: filteredItems.map((item) {
                  return GestureDetector(
                    onTap: () {
                      townController.text = item;
                      hideOverlay();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(item),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    if (dropdownHeight > 0) {
      Overlay.of(context).insert(overlayEntry!);
    } else {
      hideOverlay();
    }
  }

  hideOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  suggestions(value) {
    if (value.isEmpty) {
      filteredItems = [];
      hideOverlay();
    } else {
      filteredItems = items
          .where((item) => item.toLowerCase().contains(value.toLowerCase()))
          .toList();
      if (filteredItems.isNotEmpty) {
        showOverlay();
      } else {
        hideOverlay();
      }
    }
  }

  pickMonthYear(BuildContext context) async {
    var picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = width(context);
    return SingleChildScrollView(
      child: Container(
        height: 400,
        width: screenWidth,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30), topLeft: Radius.circular(30)),
          color: greyColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'InspectorFilterBottomSheet.filter'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_outlined,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'InspectorFilterBottomSheet.town'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              CompositedTransformTarget(
                link: layerLink,
                child: TextField(
                  controller: townController,
                  decoration: InputDecoration(
                      hintText: 'InspectorFilterBottomSheet.enterTownId'.tr(),
                      prefixIcon: Icon(
                        Icons.home_work,
                        color: borderColor,
                        size: 20,
                      ),
                      fillColor: whiteColor),
                  onChanged: (value) {
                    suggestions(value);
                    if (mounted) setState(() {});
                  },
                ),
              ),
              SizedBox(
                height: p,
              ),
              Text(
                'InspectorFilterBottomSheet.house'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                decoration: InputDecoration(
                    hintText: 'InspectorFilterBottomSheet.enterHouseId'.tr(),
                    hintStyle: TextStyle(
                      color: borderColor,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.home,
                      color: borderColor,
                      size: 20,
                    ),
                    fillColor: whiteColor),
              ),
              SizedBox(
                height: p,
              ),
              Text(
                'InspectorFilterBottomSheet.status'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      isSelected = true;
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 35,
                      width: screenWidth * 0.25,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : whiteColor,
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'InspectorFilterBottomSheet.pending'.tr(),
                          style: TextStyle(
                              color: isSelected ? whiteColor : blackColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w400),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  GestureDetector(
                    onTap: () {
                      isSelected = false;
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 35,
                      width: screenWidth * 0.25,
                      decoration: BoxDecoration(
                        color: !isSelected ? primaryColor : whiteColor,
                        border: Border.all(
                          color: isSelected ? borderColor : transparentColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'InspectorFilterBottomSheet.measured'.tr(),
                          style: TextStyle(
                              color: !isSelected ? whiteColor : blackColor,
                              fontWeight: isSelected
                                  ? FontWeight.w400
                                  : FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 39,
              ),
              Row(
                children: [
                  Expanded(
                    child: Button(
                      borderRadius: 12,
                      height: 45,
                      text: 'InspectorFilterBottomSheet.apply'.tr(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth * 0.03,
                  ),
                  Expanded(
                    child: Button(
                      borderRadius: 12,
                      height: 45,
                      text: 'InspectorFilterBottomSheet.reset'.tr(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: p,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
