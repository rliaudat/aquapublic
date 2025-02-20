import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../Components/Drawer.dart';
import '../../Components/Reuseable.dart';
import '../../Components/bottomSheets/add_update_houses.dart';
import '../../loading.dart';
import '../../theme.dart';

class HousesScreen extends StatefulWidget {
  final dynamic townId;
  final dynamic town;
  const HousesScreen({super.key, required this.townId, required this.town});

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  // Variables
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  var keyword = TextEditingController();
  List<QueryDocumentSnapshot> allData = [];
  List<QueryDocumentSnapshot> filteredData = [];
  bool addHover = false;
  bool searchHover = false;
  // Functions
  @override
  void initState() {
    loadData();
    super.initState();
  }

  loadData() {
    firestore.collection('towns').doc(widget.townId).collection('houses').where('isDelete', isEqualTo: false).orderBy('createdAt').snapshots().listen((snapshot) {
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

  deleteHouse(String houseId) async {
    await firestore.collection('towns').doc(widget.townId).collection('houses').doc(houseId).update({'isDelete': true});
    showToast(context, msg: 'House has been deleted');
  }

  showCreateUpdateBottomSheet(BuildContext context, {String? houseId, String? houseName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddUpdateHouses(houseId: houseId, houseName: houseName, townId: widget.townId, townName: widget.town),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : CustomAppBar(title: widget.town + ' Houses'),
        floatingActionButton: isTablet
            ? null
            : FloatingActionButton(
                onPressed: () => showCreateUpdateBottomSheet(context),
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTablet) const CustomDrawer(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isTablet) CustomAppBar(title: widget.town + ' Houses', showButton: false, showAction: false),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
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
                                                'Town',
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
                                                    hintText: "Search by town name",
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
                                            text: 'Search',
                                            onPressed: () {
                                              search();
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
                                              text: 'Add House',
                                              fontSize: width(context) * 0.0115,
                                              onPressed: () {
                                                showCreateUpdateBottomSheet(context);
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
                                            hintText: "Search by town name",
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
                          filteredData.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.home_rounded, size: 60, color: primaryColor),
                                      SizedBox(height: p),
                                      const Text(
                                        'No House found in this Town',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Click on + button to add new House',
                                        style: TextStyle(color: textColor),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: List.generate(
                                    filteredData.length,
                                    (index) {
                                      final house = filteredData[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: greyColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              house['name'] ?? 'Unknown House',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            PopupMenuButton(
                                              onSelected: (value) {
                                                if (value == 'Edit') {
                                                  showCreateUpdateBottomSheet(
                                                    context,
                                                    houseId: house.id,
                                                    houseName: house['name'],
                                                  );
                                                } else if (value == 'Delete') {
                                                  deleteHouse(house.id);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(value: 'Edit', child: Text('Edit')),
                                                PopupMenuItem(value: 'Delete', child: Text('Delete')),
                                              ],
                                              icon: const Icon(Icons.more_vert),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
