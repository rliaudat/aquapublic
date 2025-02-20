import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class PrivacyAndPolicyScreen extends StatefulWidget {
  const PrivacyAndPolicyScreen({super.key});

  @override
  State<PrivacyAndPolicyScreen> createState() => _PrivacyAndPolicyScreenState();
}

class _PrivacyAndPolicyScreenState extends State<PrivacyAndPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : const CustomAppBar(title: 'Privacy & Policy'),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTablet ? const CustomDrawer() : Container(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTablet ? const CustomAppBar(showButton: false, title: 'Privacy & Policy', showAction: false) : Container(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privacy & Policy for AguaMed',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'AguaMed is committed '
                            'to protecting your privacy. This Privacy Policy outlines how we collect, '
                            'use, and safeguard your information when you use our mobile application, '
                            'AguaMed.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '1. Information We Collect',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We may collect the following types of information:',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• Personal Information: We do not collect any personal information from users.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• Usage Data: We may collect data on how you use the App, including device'
                            ' information and water consumption patterns. This information is used for '
                            'demonstration purposes only.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '2. Use of Your Information',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We may use the information we collect in the following ways:',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• To demonstrate the functionality of the App.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          Text(
                            '• To analyze water consumption habits and provide insights.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          Text(
                            '• o improve the overall user experience.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '3. Data Sharing and Disclosure',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We do not share or disclose your information to third parties.'
                            ' Since this is a demo app, we do not have any data retention or user '
                            'tracking mechanisms in place.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '4. Data Security',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We take reasonable measures to protect the information collected through the App.'
                            ' However, as this is a demo'
                            ' app and does not store personal data, we cannot guarantee absolute security.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '5. Your Rights',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Since we do not collect personal information, there are no specific rights '
                            'related to your personal data. However, if you have any concerns about the '
                            'information provided in this Privacy Policy, please feel free to contact us.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '6. Changes to This Privacy Policy',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We may update this Privacy Policy from time to time. Any changes will '
                            'be effective immediately upon posting the updated Privacy Policy within '
                            'the App. We encourage you to review this Privacy Policy periodically for '
                            'any updates.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '7. Contact Us',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you have any questions about this Privacy Policy, please contact us at:',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• Email: info@aguamed.com',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
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
