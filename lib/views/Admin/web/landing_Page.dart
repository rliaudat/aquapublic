import 'dart:async';

import 'package:agua_med/Initial/auth/login.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../Components/Reuseable.dart';
import '../../../theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController scrollController = ScrollController();

  int selectedIndex = 0;

  final GlobalKey section1Key = GlobalKey();
  final GlobalKey section2Key = GlobalKey();
  final GlobalKey section3Key = GlobalKey();
  final GlobalKey section4Key = GlobalKey();

  double section1Offset = 0.0;
  double section2Offset = 0.0;
  double section3Offset = 0.0;
  double section4Offset = 0.0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
    Timer(const Duration(milliseconds: 100), () {
      getSectionOffsets();
    });
  }

  getSectionOffsets() {
    section1Offset = getOffset(section1Key);
    section2Offset = getOffset(section2Key);
    section3Offset = getOffset(section3Key);
    section4Offset = getOffset(section4Key);
    if (mounted) setState(() {});
  }

  double getOffset(GlobalKey key) {
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero).dy ?? 0.0;
  }

  onScroll() {
    double scrollPosition = scrollController.offset;

    if (scrollPosition >= section1Offset && scrollPosition < section2Offset) {
      updateSelectedIndex(0);
    } else if (scrollPosition >= section2Offset && scrollPosition < section3Offset) {
      updateSelectedIndex(1);
    } else if (scrollPosition >= section3Offset && scrollPosition < section4Offset) {
      updateSelectedIndex(2);
    } else if (scrollPosition >= section4Offset) {
      updateSelectedIndex(3);
    }
  }

  void updateSelectedIndex(int index) {
    if (selectedIndex != index) {
      selectedIndex = index;
      if (mounted) setState(() {});
    }
  }

  void scrollToSection(GlobalKey key, int index) {
    scrollController.removeListener(onScroll);
    selectedIndex = index;
    if (mounted) setState(() {});

    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        scrollController.addListener(onScroll);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: whiteColor,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AguaMed',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET))
                PopupMenuButton<int>(
                  icon: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: whiteColor,
                    ),
                    child: Center(
                      child: Icon(Icons.menu, color: primaryColor),
                    ),
                  ),
                  onSelected: (index) {
                    switch (index) {
                      case 0:
                        scrollToSection(section1Key, 0);
                        break;
                      case 1:
                        scrollToSection(section2Key, 1);
                        break;
                      case 2:
                        scrollToSection(section3Key, 2);
                        break;
                      case 3:
                        scrollToSection(section4Key, 3);
                        break;
                      case 4:
                        // Handle Download action
                        break;
                      case 5:
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 0,
                      child: Text('Home'),
                    ),
                    const PopupMenuItem(
                      value: 1,
                      child: Text('About'),
                    ),
                    const PopupMenuItem(
                      value: 2,
                      child: Text('Services'),
                    ),
                    const PopupMenuItem(
                      value: 3,
                      child: Text('Contact'),
                    ),
                    const PopupMenuItem(
                      value: 4,
                      child: Text('Download'),
                    ),
                    const PopupMenuItem(
                      value: 5,
                      child: Text('SignIn'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    WebHeader(
                      title: 'Home',
                      onTap: () {
                        selectedIndex = 1;
                        scrollToSection(section1Key, 1);
                        if (mounted) setState(() {});
                      },
                      index: 1,
                      selectedIndex: selectedIndex,
                    ),
                    WebHeader(
                      title: 'About',
                      onTap: () {
                        selectedIndex = 2;
                        scrollToSection(section2Key, 2);
                        if (mounted) setState(() {});
                      },
                      index: 2,
                      selectedIndex: selectedIndex,
                    ),
                    WebHeader(
                      title: 'Services',
                      onTap: () {
                        selectedIndex = 3;
                        scrollToSection(section3Key, 3);
                        if (mounted) setState(() {});
                      },
                      index: 3,
                      selectedIndex: selectedIndex,
                    ),
                    WebHeader(
                      title: 'Contact',
                      onTap: () {
                        selectedIndex = 4;
                        scrollToSection(section4Key, 4);
                        if (mounted) setState(() {});
                      },
                      index: 4,
                      selectedIndex: selectedIndex,
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Button(
                        borderRadius: 100,
                        height: 35,
                        width: 100,
                        textColor: darkGreyColor,
                        color: whiteColor,
                        text: 'Download',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Button(
                        borderRadius: 100,
                        height: 35,
                        width: 80,
                        color: secondaryColor,
                        textColor: greyColor,
                        text: 'SignIn',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),

            // Hero Area Start  ===============
            Container(
              key: section1Key,
              width: width(context),
              margin: EdgeInsets.symmetric(horizontal: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? 40 : 80),
              child: ResponsiveRowColumn(
                rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
                columnMainAxisAlignment: MainAxisAlignment.start,
                layout: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                children: [
                  ResponsiveRowColumnItem(
                    child: SizedBox(
                      width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 2) - 80,
                      child: Column(
                        children: [
                          Text(
                            'LandingPage.trackYourWaterUsage'.tr(),
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'LandingPage.byUsingOurApp'.tr(),
                            style: TextStyle(fontSize: 18, fontFamily: 'leon', color: darkGreyColor),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Image.asset('assets/images/appstore.png', height: 40),
                              ),
                              const SizedBox(width: 10),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Image.asset('assets/images/playstore.png', height: 40),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  ResponsiveRowColumnItem(
                    child: SizedBox(
                      width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 2) - 80,
                      child: Center(
                        child: Image.asset('assets/images/landing.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hero End

            const SizedBox(height: 80),

            // About Us Area Start  ===============
            Container(
              key: section2Key,
              width: width(context),
              margin: EdgeInsets.symmetric(horizontal: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? 40 : 80),
              decoration: BoxDecoration(color: greyColor, borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LandingPage.whoWeAre'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                    ),
                    Text(
                      'LandingPage.welcomeToAguaMed'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text(
                      'LandingPage.effortlessWaterUsageTracking'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                    SizedBox(
                      height: p,
                    ),
                    Text(
                      'LandingPage.takeControlOfYourWaterConsumption'.tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'LandingPage.secureWaterData'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                    SizedBox(height: p),
                    Text(
                      'LandingPage.atAguaMedWePrioritize'.tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'LandingPage.customerSupport'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                    SizedBox(
                      height: p,
                    ),
                    Text(
                      'LandingPage.ourCommitmentToYourSatisfaction'.tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'LandingPage.consumptionInsights'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                    SizedBox(
                      height: p,
                    ),
                    Text(
                      'LandingPage.takeControlOfYourWaterUsage'.tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'LandingPage.realTimeMonitoring'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                    ),
                    SizedBox(
                      height: p,
                    ),
                    Text(
                      'LandingPage.getInstantVisibilityIntoYourWaterConsumption'.tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            // About Us End

            const SizedBox(height: 80),

            // Our Principles Area Start  ===============
            Container(
              width: width(context),
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? 40 : 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'LandingPage.ourPrinciples'.tr(),
                    style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'LandingPage.weStronglyStandOnOurThreeMainPrinciples'.tr(),
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ResponsiveRowColumn(
                    rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
                    columnMainAxisAlignment: MainAxisAlignment.start,
                    layout: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                    children: [
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(
                            color: greyColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset(
                                'assets/images/support.png',
                                width: 80,
                                color: blackColor,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.fastService'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  textAlign: TextAlign.center,
                                  'LandingPage.weOfferFastAndReliableService'.tr(),
                                  style: TextStyle(fontSize: 18),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const ResponsiveRowColumnItem(child: SizedBox(height: 20)),
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(color: greyColor, borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset('assets/images/professional.png', width: 80),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.professionalInteractions'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  'LandingPage.ourTechniciansUpholdTheHighestLevelOfProfessionalism'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const ResponsiveRowColumnItem(child: SizedBox(height: 20)),
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(color: greyColor, borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset('assets/images/gloves.png', width: 80),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.whiteGloveService'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  'LandingPage.weHandleAllTheDetails'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Our Principles End

            const SizedBox(height: 80),

            // Our Services Area Start  ===============
            Container(
              width: width(context),
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? 40 : 80,
              ),
              key: section3Key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'LandingPage.ourServices'.tr(),
                    style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'LandingPage.weOfferAWideRangeOfServices'.tr(),
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ResponsiveRowColumn(
                    rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
                    columnMainAxisAlignment: MainAxisAlignment.start,
                    layout: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                    children: [
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(
                            color: greyColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset(
                                'assets/images/alert.png',
                                width: 80,
                                color: blackColor,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.instantAlerts'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  textAlign: TextAlign.center,
                                  'LandingPage.receiveInstantUpdatesOnMeterReadings'.tr(),
                                  style: TextStyle(fontSize: 18),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const ResponsiveRowColumnItem(child: SizedBox(height: 20)),
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(color: greyColor, borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset('assets/images/security.png', width: 80),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.dataSecurity'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  'LandingPage.accessYourWaterConsumptionDataSecurely'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const ResponsiveRowColumnItem(child: SizedBox(height: 20)),
                      ResponsiveRowColumnItem(
                        child: Container(
                          height: 400,
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 3) - 65,
                          decoration: BoxDecoration(color: greyColor, borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Image.asset('assets/images/tip.png', width: 80),
                              const SizedBox(height: 20),
                              Text(
                                textAlign: TextAlign.center,
                                'LandingPage.savingsTips'.tr(),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Text(
                                  'LandingPage.getTailoredSuggestionsToHelpYouReduceWaterWaste'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Our Services End

            const SizedBox(height: 80),

            // Footer Area Start  ===============
            Container(
              width: width(context),
              key: section4Key,
              padding: EdgeInsets.symmetric(horizontal: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? 40 : 80),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  ResponsiveRowColumn(
                    rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
                    columnMainAxisAlignment: MainAxisAlignment.start,
                    layout: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                    children: [
                      ResponsiveRowColumnItem(
                        child: SizedBox(
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 2) - 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: whiteColor),
                                    child: Center(
                                      child: Image.asset('assets/images/icon.png', width: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AguaMed',
                                    style: TextStyle(color: whiteColor, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'LandingPage.supportEmail'.tr(),
                                    style: TextStyle(color: whiteColor, fontSize: 16),
                                  ),
                                  SizedBox(width: p),
                                  Text('|', style: TextStyle(color: whiteColor, fontSize: 16)),
                                  SizedBox(width: p),
                                  Text(
                                    'LandingPage.supportPhone'.tr(),
                                    style: TextStyle(color: whiteColor, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: whiteColor, width: 2)),
                                      child: Center(child: Image.asset('assets/images/instagram.png', color: whiteColor, width: 20)),
                                    ),
                                  ),
                                  SizedBox(width: p),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: whiteColor, width: 2)),
                                      child: Center(child: Image.asset('assets/images/facebook.png', color: whiteColor, width: 20)),
                                    ),
                                  ),
                                  SizedBox(width: p),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: whiteColor, width: 2)),
                                      child: Center(child: Image.asset('assets/images/youtube.png', color: whiteColor, width: 20)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ResponsiveRowColumnItem(
                        child: SizedBox(
                          width: ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) ? width(context) - 40 : (width(context) / 2) - 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'LandingPage.downloadTheApp'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: whiteColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Image.asset('assets/images/appstore.png', height: 30),
                                  ),
                                  const SizedBox(width: 10),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Image.asset('assets/images/playstore.png', height: 30),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('LandingPage.copyright'.tr(), style: TextStyle(fontSize: 18, color: whiteColor)),
                  const SizedBox(height: 50),
                ],
              ),
            ),
            // Footer End
          ],
        ),
      ),
    );
  }
}
