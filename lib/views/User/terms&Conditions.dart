import 'package:agua_med/loading.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../Components/Drawer.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() => _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return GestureDetector(
      onTap: () => unFocus(context),
      child: Scaffold(
        appBar: isTablet ? null : const CustomAppBar(title: 'Terms & Conditions'),
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
                    isTablet ? const CustomAppBar(title: 'Terms & Conditions', showAction: false, showButton: false) : Container(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Terms & Conditions for AguaMed',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to AguaMed. By accessing or '
                            'using our App, you agree to comply with and be bound by the '
                            'following terms and conditions. Please read these Terms and'
                            ' Conditions carefully. If you do not agree with these terms, '
                            'you must not use the App.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '1. Acceptance of Terms',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By using the App, you acknowledge that you have read, '
                            'understood, and agree to be bound by these Terms and Conditions.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '2. Use of the App',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• The App is designed for demonstration purposes only.'
                            ' You may use the App for personal and non-commercial purposes.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• You agree not to use the App for any illegal or unauthorized purposes.'
                            ' You must not violate any laws in your jurisdiction while using the App.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '3. User Accounts',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No user accounts are required to use this demo App. Any data '
                            'collected is for demonstration purposes only and is not stored or tracked.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '4. Intellectual Property',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The App and its original content, features, and functionality are owned'
                            ' by AguaMed and are protected by international copyright, trademark, '
                            'patent, trade secret, and other intellectual property or proprietary rights laws.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '5. Disclaimer of Warranties',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We do not guarantee that the App will be uninterrupted, secure,'
                            ' or error-free, nor do we warrant the accuracy or reliability of '
                            'any information obtained through the App.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '6. Limitation of Liability',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'In no event shall AguaMed, its directors, employees,'
                            ' or agents be liable for any indirect, incidental, special, consequential, '
                            'or punitive damages arising out of or related to your use of the App.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '7. Modifications to Terms',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We reserve the right to modify these Terms and Conditions at any time.'
                            ' Any changes will be effective immediately upon posting the updated Terms'
                            ' within the App. Your continued use of the App after any changes signifies'
                            ' your acceptance of the new Terms.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '8. Governing Law',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These Terms and Conditions shall be governed by and construed '
                            'in accordance with the laws of [Your Jurisdiction], without regard to '
                            'its conflict of law principles.',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          SizedBox(height: p),
                          const Text(
                            '9. Contact Us',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you have any questions or concerns regarding these Terms and Conditions, please contact us at:',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• Email: info@aguamed.com',
                            style: TextStyle(color: darkGreyColor),
                          ),
                          const SizedBox(height: 30),
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
