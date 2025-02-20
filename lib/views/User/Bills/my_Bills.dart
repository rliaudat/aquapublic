import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/User/Bills/bill_Detail.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MyBillsScreen extends StatefulWidget {
  const MyBillsScreen({super.key});

  @override
  State<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends State<MyBillsScreen> {
  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return Scaffold(
      appBar: isTablet
          ? null
          : const CustomAppBar(
              title: 'My Bills',
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isTablet ? const CustomDrawer() : Container(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: p),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isTablet
                      ? const CustomAppBar(
                          title: 'My Bills',
                          showAction: false,
                          showButton: false,
                        )
                      : Container(),
                  const SizedBox(
                    height: 30,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BillDetailScreen()));
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: greyColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/icon.png',
                                    width: 45,
                                  ),
                                  SizedBox(
                                    width: width(context) * 0.01,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AguaMed',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'John Doe',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: darkGreyColor),
                                      ),
                                      Text(
                                        '+9228829299',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: darkGreyColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$239',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreyColor, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: width(context) * 0.02,
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: secondaryColor,
                                    size: 20,
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
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
