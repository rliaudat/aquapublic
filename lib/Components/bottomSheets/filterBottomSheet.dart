import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../theme.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedOption;
  DateTime? selectedDate;

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
  void initState() {
    super.initState();
    selectedOption = 'Newest';
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return SingleChildScrollView(
      child: Container(
        height: isTablet ? 410 : 405,
        width: width(context),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
          color: greyColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: p),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FilterBottomSheet.sortAndFilter'.tr(),
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
              const SizedBox(height: 20),
              Text(
                'FilterBottomSheet.sort'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: width(context),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: selectedOption,
                    icon: Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: borderColor,
                    ),
                    iconSize: 20,
                    elevation: 0,
                    style: TextStyle(color: blackColor),
                    onChanged: (String? newValue) {
                      selectedOption = newValue;
                      if (mounted) setState(() {});
                    },
                    items: ['FilterBottomSheet.newest'.tr(), 'FilterBottomSheet.relevant'.tr()].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: p),
              Text(
                'FilterBottomSheet.town'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                    hintText: "FilterBottomSheet.enterTownId".tr(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    hintStyle: TextStyle(
                      color: blackColor,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.home_work_outlined,
                      color: borderColor,
                      size: 20,
                    ),
                    fillColor: whiteColor),
              ),
              SizedBox(height: p),
              Text(
                'FilterBottomSheet.month'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => pickMonthYear(context),
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: p),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(radius),
                    color: whiteColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null ? '${selectedDate!.month}/${selectedDate!.year}' : 'FilterBottomSheet.selectMonthYear'.tr(),
                      ),
                      Icon(Icons.calendar_today, color: borderColor, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Button(borderRadius: 12, height: 45, text: 'FilterBottomSheet.apply'.tr(), onPressed: () => Navigator.pop(context)),
                  ),
                  SizedBox(
                    width: width(context) * 0.03,
                  ),
                  Expanded(
                    child: Button(borderRadius: 12, height: 45, text: 'FilterBottomSheet.reset'.tr(), onPressed: () => Navigator.pop(context)),
                  )
                ],
              ),
              SizedBox(height: p),
            ],
          ),
        ),
      ),
    );
  }
}
