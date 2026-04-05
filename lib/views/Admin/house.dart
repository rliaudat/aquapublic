import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/providers/house_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../Components/Reuseable.dart';
import '../../Components/bottomSheets/add_update_houses.dart';
import '../../loading.dart';
import '../../theme.dart';

class HousesScreen extends StatelessWidget {
  final String townID;
  final String town;
  const HousesScreen({super.key, required this.townID, required this.town});
  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet
            ? CustomAppBar(
                title: '$town Houses', showButton: true, showAction: false)
            : CustomAppBar(title: '$town Houses'),
        floatingActionButton: isTablet
            ? null
            : FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => AddUpdateHouses(
                    townId: townID,
                    townName: town,
                  ),
                ),
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
        body: Consumer<HouseProvider>(builder: (context, provider, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                                      borderRadius:
                                          BorderRadius.circular(radius),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Town',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: darkGreyColor),
                                                ),
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  height: 45,
                                                  child: TextField(
                                                    onChanged: (value) {
                                                      provider.setQuery(value);
                                                    },
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          "Search by house name",
                                                      prefixIcon: Icon(
                                                        Icons.search_rounded,
                                                        size: 18,
                                                        color: borderColor,
                                                      ),
                                                      suffixIcon: provider
                                                                      .query !=
                                                                  null ||
                                                              provider.query !=
                                                                  ''
                                                          ? IconButton(
                                                              icon: Icon(
                                                                  Icons.clear,
                                                                  color:
                                                                      borderColor,
                                                                  size: 18),
                                                              onPressed: () {
                                                                provider
                                                                    .clearQuery();
                                                              },
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              width: width(context) * 0.01),
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => provider
                                                .setSearchButtonHover(true),
                                            onExit: (_) => provider
                                                .setSearchButtonHover(false),
                                            child: Button(
                                              color: provider.searchButtonHover
                                                  ? primaryColor
                                                  : secondaryColor,
                                              borderRadius: radius,
                                              height: 45,
                                              fontSize: width(context) * 0.0115,
                                              width: width(context) / 9,
                                              text: 'Search',
                                              onPressed: () {},
                                            ),
                                          ),
                                          SizedBox(
                                              width: width(context) * 0.005),
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => provider
                                                .setAddButtonHover(true),
                                            onExit: (_) => provider
                                                .setAddButtonHover(false),
                                            child: Button(
                                                color: provider.addButtonHover
                                                    ? primaryColor
                                                    : secondaryColor,
                                                borderRadius: radius,
                                                height: 45,
                                                width: width(context) / 9,
                                                text: 'Add House',
                                                fontSize:
                                                    width(context) * 0.0115,
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    builder: (context) =>
                                                        AddUpdateHouses(
                                                      townId: townID,
                                                      townName: town,
                                                    ),
                                                  );
                                                }),
                                          ),
                                          SizedBox(
                                              width: width(context) * 0.005),
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => provider
                                                .setSearchButtonHover(true),
                                            onExit: (_) => provider
                                                .setSearchButtonHover(false),
                                            child: Button(
                                              color: provider.searchButtonHover
                                                  ? primaryColor
                                                  : secondaryColor,
                                              borderRadius: radius,
                                              height: 45,
                                              fontSize: width(context) * 0.0115,
                                              width: width(context) / 9,
                                              text: 'Import',
                                              onPressed: () {
                                                provider.importHousesFromCsv(
                                                  context,
                                                  townID,
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                              width: width(context) * 0.005),
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => provider
                                                .setExportButtonHover(true),
                                            onExit: (_) => provider
                                                .setExportButtonHover(false),
                                            child: Button(
                                              color: provider.exportButtonHover
                                                  ? primaryColor
                                                  : secondaryColor,
                                              borderRadius: radius,
                                              height: 45,
                                              fontSize: width(context) * 0.0115,
                                              width: width(context) / 9,
                                              text: 'Export',
                                              onPressed: () {
                                                provider.exportHousesToExcel(
                                                    context, townID);
                                              },
                                            ),
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
                                            onChanged: (value) {
                                              provider.setQuery(value);
                                            },
                                            decoration: InputDecoration(
                                              hintText: "Search by town name",
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                                size: 18,
                                                color: borderColor,
                                              ),
                                              suffixIcon: provider.query !=
                                                          null ||
                                                      provider.query != ''
                                                  ? IconButton(
                                                      icon: Icon(Icons.clear,
                                                          color: borderColor,
                                                          size: 18),
                                                      onPressed: () {
                                                        provider.clearQuery();
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
                                          onTap: () {},
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: primaryColor,
                                            ),
                                            child: Icon(Icons.search_rounded,
                                                size: 24, color: whiteColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 20),
                            StreamBuilder(
                              stream: HouseServices.houseStream(townID),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox();
                                } else {
                                  if (snapshot.data?.isEmpty ?? true) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.home_rounded,
                                              size: 60, color: primaryColor),
                                          SizedBox(height: p),
                                          const Text(
                                            'No House found in this Town',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Click on + button to add new House',
                                            style: TextStyle(color: textColor),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Column(
                                      children: List.generate(
                                        snapshot.data?.length ?? 0,
                                        (index) {
                                          final house = snapshot.data![index];
                                          return house.name
                                                  .toLowerCase()
                                                  .contains(provider.query
                                                          ?.toLowerCase() ??
                                                      '')
                                              ? Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 8),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: greyColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        house.name,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      PopupMenuButton(
                                                        onSelected: (value) {
                                                          if (value == 'Edit') {
                                                            showModalBottomSheet(
                                                              context: context,
                                                              isScrollControlled:
                                                                  true,
                                                              builder: (context) =>
                                                                  AddUpdateHouses(
                                                                houseId:
                                                                    house.id,
                                                                houseName:
                                                                    house.name,
                                                                cohabitants: house
                                                                    .cohabitants,
                                                                meterNumber: house
                                                                    .meterNumber,
                                                                houseType: house
                                                                    .houseType,
                                                                townId: townID,
                                                                townName: town,
                                                              ),
                                                            );
                                                          } else if (value ==
                                                              'Delete') {
                                                            HouseServices
                                                                .update(
                                                              house.id,
                                                              {
                                                                'isDelete': true
                                                              },
                                                            );
                                                            showToast(context,
                                                                msg:
                                                                    'House has been deleted');
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (context) => const [
                                                          PopupMenuItem(
                                                              value: 'Edit',
                                                              child:
                                                                  Text('Edit')),
                                                          PopupMenuItem(
                                                              value: 'Delete',
                                                              child: Text(
                                                                  'Delete')),
                                                        ],
                                                        icon: const Icon(
                                                            Icons.more_vert),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox();
                                        },
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
