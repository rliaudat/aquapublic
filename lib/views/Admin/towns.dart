import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/Components/bottomSheets/add_update_town.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/views/Admin/house.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../Components/Drawer.dart';
import '../../theme.dart';

class TownsScreen extends StatefulWidget {
  const TownsScreen({super.key});

  @override
  State<TownsScreen> createState() => _TownsScreenState();
}

class _TownsScreenState extends State<TownsScreen> {
  // Variables
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool addHover = false;
  bool searchHover = false;
  var keyword = TextEditingController();
  List<QueryDocumentSnapshot> allData = [];
  List<QueryDocumentSnapshot> filteredData = [];

  // Functions
  @override
  void initState() {
    loadData();
    super.initState();
  }

  loadData() {
    firestore.collection('towns').where('isDelete', isEqualTo: false).orderBy('createdAt').snapshots().listen((snapshot) {
      allData = snapshot.docs;
      filteredData = List.from(allData);
      if (mounted) setState(() {});
    });
  }

  search() {
    filteredData = keyword.text.isEmpty
        ? allData
        : allData.where((doc) {
            final townName = (doc['name'] as String).toLowerCase();
            return townName.contains(keyword.text.toLowerCase());
          }).toList();
    if (mounted) setState(() {});
  }

  addUpdateTownSheet(
    BuildContext context, {
    String? townId,
    String? townName,
    String? townUnitPrice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddUpdateTown(townId: townId, townName: townName, townUnitPrice: townUnitPrice);
      },
    );
  }

  deleteTown(String townId) async {
    try {
      await firestore.collection('towns').doc(townId).update({'isDelete': true});
      showToast(context, msg: 'TownsScreen.townSuccessfullyDeleted'.tr());
    } on FirebaseException catch (e) {
      showToast(context, msg: e.message!);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Scaffold(
      appBar: isTablet ? null : CustomAppBar(title: 'TownsScreen.town'.tr()),
      floatingActionButton: isTablet
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                addUpdateTownSheet(context);
              },
              backgroundColor: primaryColor,
              child: Icon(
                Icons.add,
                color: whiteColor,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isTablet ? const CustomDrawer() : Container(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  isTablet ? CustomAppBar(title: 'TownsScreen.town'.tr(), showButton: false, showAction: false) : Container(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: p),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Search and Add Button Section
                        isTablet
                            ? Container(
                                height: 95,
                                width: width(context),
                                decoration: BoxDecoration(
                                  color: greyColor,
                                  borderRadius: BorderRadius.circular(radius),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'TownsScreen.town'.tr(),
                                              style: TextStyle(fontWeight: FontWeight.bold, color: darkGreyColor),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              height: 45,
                                              child: TextField(
                                                controller: keyword,
                                                onChanged: (value) {
                                                  search();
                                                },
                                                decoration: InputDecoration(
                                                  hintText: "TownsScreen.searchByTownName".tr(),
                                                  prefixIcon: Icon(
                                                    Icons.search_rounded,
                                                    size: 18,
                                                    color: borderColor,
                                                  ),
                                                  suffixIcon: keyword.text.isNotEmpty
                                                      ? IconButton(
                                                          icon: Icon(Icons.clear, color: borderColor, size: 18),
                                                          onPressed: () {
                                                            keyword.clear();
                                                            if (mounted) setState(() {});
                                                          },
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: width(context) * 0.01),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) => setState(() => searchHover = true),
                                        onExit: (_) => setState(() => searchHover = false),
                                        child: Button(
                                          color: searchHover ? primaryColor : secondaryColor,
                                          borderRadius: radius,
                                          height: 45,
                                          fontSize: width(context) * 0.0115,
                                          width: width(context) / 9,
                                          text: 'TownsScreen.search'.tr(),
                                          onPressed: () {
                                            search();
                                            if (mounted) setState(() {});
                                          },
                                        ),
                                      ),
                                      SizedBox(width: width(context) * 0.01),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) => setState(() => addHover = true),
                                        onExit: (_) => setState(() => addHover = false),
                                        child: Button(
                                            color: addHover ? primaryColor : secondaryColor,
                                            borderRadius: radius,
                                            height: 45,
                                            width: width(context) / 9,
                                            text: 'TownsScreen.addTown'.tr(),
                                            fontSize: width(context) * 0.0115,
                                            onPressed: () {
                                              addUpdateTownSheet(context);
                                            }),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Flexible(
                                    child: SizedBox(
                                      height: 45,
                                      child: TextField(
                                        controller: keyword,
                                        onChanged: (value) {
                                          search();
                                        },
                                        decoration: InputDecoration(
                                          hintText: "TownsScreen.searchByTownName".tr(),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                            color: borderColor,
                                          ),
                                          suffixIcon: keyword.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear, color: borderColor, size: 18),
                                                  onPressed: () {
                                                    keyword.clear();
                                                    if (mounted) setState(() {});
                                                  },
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: width(context) * 0.01),
                                  Flexible(
                                    flex: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        search();
                                      },
                                      child: Container(
                                        height: 45,
                                        width: 45,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor,
                                        ),
                                        child: Icon(Icons.search_rounded, size: 24, color: whiteColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 20),
                        // Display Towns or No Search Results
                        filteredData.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 180),
                                  Icon(Icons.home_work_rounded, size: 60, color: primaryColor),
                                  SizedBox(height: p),
                                  Text(
                                    'TownsScreen.noTownFoundYet'.tr(),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'TownsScreen.clickOnAddButtonToAddNewTown'.tr(),
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              )
                            : Wrap(
                                children: List.generate(filteredData.length, (index) {
                                  final data = filteredData[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => HousesScreen(townId: data.id, town: data['name'])),
                                      );
                                    },
                                    child: Container(
                                      height: 60,
                                      width: width(context),
                                      margin: EdgeInsets.only(bottom: p),
                                      padding: EdgeInsets.only(left: p),
                                      decoration: BoxDecoration(
                                        color: greyColor,
                                        borderRadius: BorderRadius.circular(radius),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data['name'],
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreyColor),
                                                  ),
                                                  Text(
                                                    "TownsScreen.perUnitPrice".tr(args: [data['unitPrice'].toString()]),
                                                    style: TextStyle(
                                                      color: darkGreyColor,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              PopupMenuButton(
                                                menuPadding: const EdgeInsets.only(bottom: 0),
                                                color: greyColor,
                                                position: PopupMenuPosition.under,
                                                shape: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
                                                onSelected: (value) async {
                                                  if (value == 'Edit') {
                                                    addUpdateTownSheet(
                                                      context,
                                                      townId: data.id,
                                                      townName: data['name'],
                                                      townUnitPrice: data['unitPrice'],
                                                    );
                                                  } else if (value == 'Delete') {
                                                    await deleteTown(data.id);
                                                  }
                                                },
                                                itemBuilder: (BuildContext context) {
                                                  return [
                                                    PopupMenuItem(
                                                      value: 'Edit',
                                                      child: Text('TownsScreen.edit'.tr()),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'Delete',
                                                      child: Text('TownsScreen.delete'.tr()),
                                                    ),
                                                  ];
                                                },
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: borderColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
