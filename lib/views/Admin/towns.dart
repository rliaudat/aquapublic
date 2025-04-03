import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/Components/bottomSheets/add_update_town.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/providers/town_provider.dart';
import 'package:agua_med/views/Admin/house.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../Components/Drawer.dart';
import '../../theme.dart';

class TownsScreen extends StatelessWidget {
  const TownsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Scaffold(
      appBar: isTablet ? null : CustomAppBar(title: 'TownsScreen.town'.tr()),
      floatingActionButton: isTablet
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return const AddUpdateTown();
                  },
                );
              },
              backgroundColor: primaryColor,
              child: Icon(
                Icons.add,
                color: whiteColor,
              ),
            ),
      body: Consumer<TownProvider>(builder: (context, provider, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    isTablet
                        ? CustomAppBar(
                            title: 'TownsScreen.town'.tr(),
                            showButton: false,
                            showAction: false,
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          isTablet
                              ? Container(
                                  height: 95,
                                  width: width(context),
                                  decoration: BoxDecoration(
                                    color: greyColor,
                                    borderRadius: BorderRadius.circular(radius),
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
                                                'TownsScreen.town'.tr(),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
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
                                                        "TownsScreen.searchByTownName"
                                                            .tr(),
                                                    prefixIcon: Icon(
                                                      Icons.search_rounded,
                                                      size: 18,
                                                      color: borderColor,
                                                    ),
                                                    suffixIcon: provider
                                                                    .query !=
                                                                null ||
                                                            provider.query != ''
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
                                        SizedBox(width: width(context) * 0.01),
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
                                            text: 'TownsScreen.search'.tr(),
                                            onPressed: () {},
                                          ),
                                        ),
                                        SizedBox(width: width(context) * 0.01),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) =>
                                              provider.setAddButtonHover(true),
                                          onExit: (_) =>
                                              provider.setAddButtonHover(false),
                                          child: Button(
                                              color: provider.addButtonHover
                                                  ? primaryColor
                                                  : secondaryColor,
                                              borderRadius: radius,
                                              height: 45,
                                              width: width(context) / 9,
                                              text: 'TownsScreen.addTown'.tr(),
                                              fontSize: width(context) * 0.0115,
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder:
                                                      (BuildContext context) {
                                                    return const AddUpdateTown();
                                                  },
                                                );
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
                                          onChanged: (value) {
                                            provider.setQuery(value);
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                "TownsScreen.searchByTownName"
                                                    .tr(),
                                            prefixIcon: Icon(
                                              Icons.search_rounded,
                                              size: 18,
                                              color: borderColor,
                                            ),
                                            suffixIcon:
                                                provider.query != null ||
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
                            stream: TownServices.townStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox();
                              } else {
                                if (snapshot.data?.isEmpty ?? true) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 180),
                                      Icon(Icons.home_work_rounded,
                                          size: 60, color: primaryColor),
                                      SizedBox(height: p),
                                      Text(
                                        'TownsScreen.noTownFoundYet'.tr(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'TownsScreen.clickOnAddButtonToAddNewTown'
                                            .tr(),
                                        style: TextStyle(color: textColor),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Wrap(
                                    children: List.generate(
                                        snapshot.data?.length ?? 0, (index) {
                                      final data = snapshot.data![index];
                                      return data.name
                                              .contains(provider.query ?? '')
                                          ? GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        HousesScreen(
                                                      townID: data.id,
                                                      town: data.name,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 60,
                                                width: width(context),
                                                margin:
                                                    EdgeInsets.only(bottom: p),
                                                padding:
                                                    EdgeInsets.only(left: p),
                                                decoration: BoxDecoration(
                                                  color: greyColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          radius),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              data.name,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      darkGreyColor),
                                                            ),
                                                            Text(
                                                              "TownsScreen.perUnitPrice"
                                                                  .tr(args: [
                                                                data.unitPrice
                                                                    .toString()
                                                              ]),
                                                              style: TextStyle(
                                                                color:
                                                                    darkGreyColor,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        PopupMenuButton(
                                                          menuPadding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 0),
                                                          color: greyColor,
                                                          position:
                                                              PopupMenuPosition
                                                                  .under,
                                                          shape: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          radius),
                                                              borderSide:
                                                                  BorderSide
                                                                      .none),
                                                          onSelected:
                                                              (value) async {
                                                            if (value ==
                                                                'Edit') {
                                                              showModalBottomSheet(
                                                                context:
                                                                    context,
                                                                isScrollControlled:
                                                                    true,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return AddUpdateTown(
                                                                    townId:
                                                                        data.id,
                                                                    townName:
                                                                        data.name,
                                                                    townUnitPrice: data
                                                                        .unitPrice
                                                                        .toString(),
                                                                  );
                                                                },
                                                              );
                                                            } else if (value ==
                                                                'Delete') {
                                                              try {
                                                                TownServices
                                                                    .update(
                                                                        context,
                                                                        data.id,
                                                                        {
                                                                      'isDelete':
                                                                          true
                                                                    });
                                                                showToast(
                                                                    context,
                                                                    msg: 'TownsScreen.townSuccessfullyDeleted'
                                                                        .tr());
                                                              } on FirebaseException catch (e) {
                                                                showToast(
                                                                    context,
                                                                    msg: e
                                                                        .message!);
                                                              }
                                                            }
                                                          },
                                                          itemBuilder:
                                                              (BuildContext
                                                                  context) {
                                                            return [
                                                              PopupMenuItem(
                                                                value: 'Edit',
                                                                child: Text(
                                                                    'TownsScreen.edit'
                                                                        .tr()),
                                                              ),
                                                              PopupMenuItem(
                                                                value: 'Delete',
                                                                child: Text(
                                                                    'TownsScreen.delete'
                                                                        .tr()),
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
                                            )
                                          : const SizedBox();
                                    }),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
