import 'package:agua_med/Initial/auth/login.dart';
import 'package:agua_med/bloc/authentication/authentication_bloc.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/views/Admin/admin_home.dart';
import 'package:agua_med/views/Admin/web/landing_Page.dart';
import 'package:agua_med/views/Inspector/inspector_home.dart';
import 'package:agua_med/views/Manager/manager_home.dart';
import 'package:agua_med/views/User/home.dart';
import 'package:agua_med/views/User/web_dashboard.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
    BlocProvider.of<AuthenticationBloc>(context).add(
      CheckAuth(kIsWeb: kIsWeb),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          if (kIsWeb) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
        if (state is Authenticated) {
          context.read<UserProvider>().setUser(state.user);
          if (state.user.role == 'Manager') {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => isDesktop
                        ? const UserWebDashboardPage()
                        : const ManagerHomeScreen()),
                (route) => false);
          } else if (state.user.role == 'Inspector') {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const InspectorHomeScreen()),
                (route) => false);
          } else if (state.user.role == 'HouseOwner') {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => isDesktop
                      ? const UserWebDashboardPage()
                      : const HomeScreen(),
                ),
                (route) => false);
          } else if (state.user.role == 'Admin') {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen()),
                (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false);
          }
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}
