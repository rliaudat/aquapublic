import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../theme.dart';

class GlobalFilterBottomSheet extends StatefulWidget {
  const GlobalFilterBottomSheet({super.key});

  @override
  State<GlobalFilterBottomSheet> createState() => _GlobalFilterBottomSheetState();
}

class _GlobalFilterBottomSheetState extends State<GlobalFilterBottomSheet> {
  String? selectedOption;
  DateTime? selectedDate;
  int selectedIndex = 0;

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
    selectedOption = 'newest'.tr();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return SingleChildScrollView(
      child: Container(
        height: 400,
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
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GlobalFilterBottomSheet.sortAndFilter'.tr(),
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
                'GlobalFilterBottomSheet.sort'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
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
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    iconSize: 20,
                    elevation: 16,
                    style: TextStyle(color: blackColor),
                    onChanged: (String? newValue) {
                      selectedOption = newValue;
                      if (mounted) setState(() {});
                    },
                    items: ['newest'.tr(), 'relevant'.tr()].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontFamily: 'cabin bold',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(
                height: p,
              ),
              Text(
                'GlobalFilterBottomSheet.town'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                decoration: InputDecoration(
                    hintText: "GlobalFilterBottomSheet.enterTownId".tr(),
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
              SizedBox(
                height: p,
              ),
              Text(
                'GlobalFilterBottomSheet.status'.tr(),
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
                      selectedIndex = 0;
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 35,
                      width: isTablet ? width(context) * 0.10 : width(context) * 0.25,
                      decoration: BoxDecoration(
                        color: selectedIndex == 0 ? primaryColor : transparentColor,
                        border: Border.all(
                          color: selectedIndex == 0 ? primaryColor : borderColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'GlobalFilterBottomSheet.registered'.tr(),
                          style: TextStyle(
                            color: selectedIndex == 0 ? whiteColor : blackColor,
                            fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width(context) * 0.02),
                  GestureDetector(
                    onTap: () {
                      selectedIndex = 1;
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 35,
                      width: isTablet ? width(context) * 0.10 : width(context) * 0.25,
                      decoration: BoxDecoration(
                        color: selectedIndex == 1 ? primaryColor : transparentColor,
                        border: Border.all(
                          color: selectedIndex == 1 ? primaryColor : borderColor,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'GlobalFilterBottomSheet.blocked'.tr(),
                          style: TextStyle(
                            color: selectedIndex == 1 ? whiteColor : blackColor,
                            fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isTablet ? 30 : 40,
              ),
              Row(
                children: [
                  Expanded(
                    child: Button(
                      borderRadius: 12,
                      height: 45,
                      text: 'GlobalFilterBottomSheet.apply'.tr(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(
                    width: width(context) * 0.03,
                  ),
                  Expanded(
                    child: Button(
                      borderRadius: 12,
                      height: 45,
                      text: 'GlobalFilterBottomSheet.reset'.tr(),
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
