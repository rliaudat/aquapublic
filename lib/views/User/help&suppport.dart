import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../Components/Drawer.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : const CustomAppBar(title: 'Help & Support'),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: p),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isTablet
                          ? const CustomAppBar(
                              title: 'Help & Support',
                              showButton: false,
                            )
                          : Container(),
                      const SizedBox(
                        height: 30,
                      ),
                      Center(
                        child: Container(
                          width: isTablet ? 400 : width(context),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isTablet ? darkGreyColor : transparentColor,
                                width: isTablet ? 0 : 0.5,
                              )),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? p : 0.0, vertical: isTablet ? 16.0 : 0.0),
                            child: Column(
                              children: [
                                const Center(
                                  child: Text(
                                      textAlign: TextAlign.center,
                                      "Need assistance or have a question?\nOur customer service "
                                      "team is here to help! Please fill out\nthe contact form below"
                                      " with your details and inquiry, and\nwe'll get back to you as soon as possible."),
                                ),
                                const SizedBox(
                                  height: 40,
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Enter Full Name ',
                                  ),
                                ),
                                SizedBox(
                                  height: p,
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email Adress',
                                  ),
                                ),
                                SizedBox(
                                  height: p,
                                ),
                                const TextField(
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 10,
                                  decoration: InputDecoration(
                                    hintText: 'Tell Us a littel about How we can Help you ',
                                  ),
                                ),
                                SizedBox(
                                  height: isTablet ? 50 : 135,
                                ),
                                Button(
                                  height: 50,
                                  width: width(context),
                                  text: 'Submit',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isTablet ? 30 : 0,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
