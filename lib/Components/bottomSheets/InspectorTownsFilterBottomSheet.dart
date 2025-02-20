import 'package:agua_med/_helpers/global.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class InspectorTownsFilterBottomSheet extends StatefulWidget {
  final List towns;
  final ValueChanged onSelected;

  const InspectorTownsFilterBottomSheet({
    super.key,
    required this.towns,
    required this.onSelected,
  });

  @override
  _InspectorTownsFilterBottomSheetState createState() => _InspectorTownsFilterBottomSheetState();
}

class _InspectorTownsFilterBottomSheetState extends State<InspectorTownsFilterBottomSheet> {
  var selected = '';

  @override
  void initState() {
    selected = selectedTown['id'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: greyColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'InspectorTownsFilterBottomSheet.selectTown'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Town List with Enhanced UI
            Expanded(
              child: ListView.builder(
                itemCount: widget.towns.length,
                itemBuilder: (context, index) {
                  var item = widget.towns[index];

                  return GestureDetector(
                    onTap: () {
                      widget.onSelected(item);
                      selected = item['id'];
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: selected == item['id'] ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: selected == item['id'] ? primaryColor : Colors.grey.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected == item['id'] ? FontWeight.bold : FontWeight.normal,
                              color: selected == item['id'] ? whiteColor : blackColor,
                            ),
                          ),
                          if (selected == item['id']) Icon(Icons.check, color: whiteColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
