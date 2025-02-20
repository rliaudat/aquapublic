import 'dart:async';
import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../_helpers/global.dart';
import '../_services/storage.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: kIsWeb ? 1 : 2), () {
      goNext();
    });
  }

  goNext() {
    Storage.getLogin().then((val) {
      if (val == false) {
        if (kIsWeb) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
          return;
        }
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      } else {
        userSD = val;
        String role = userSD['role'];

        if (role == 'Manager') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManagerHomeScreen()), (route) => false);
        } else if (role == 'Inspector') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const InspectorHomeScreen()), (route) => false);
        } else if (role == 'HouseOwner') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
        } else if (role == 'Admin') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()), (route) => false);
        } else {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/icon.png', width: 100),
            SizedBox(height: p),
            AnimatedTextKit(
              animatedTexts: [
                ColorizeAnimatedText(
                  'AguaMED',
                  textStyle: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  colors: [primaryColor, blueColor],
                ),
              ],
              isRepeatingAnimation: false,
              repeatForever: false,
            ),
          ],
        ),
      ),
    );
  }
}
