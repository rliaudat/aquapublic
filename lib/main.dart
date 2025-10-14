import 'dart:ui';
import 'package:agua_med/bloc/authentication/authentication_bloc.dart';
import 'package:agua_med/Initial/splashScreen.dart';
import 'package:agua_med/providers/admin_home_provider.dart';
import 'package:agua_med/providers/admin_invoice_provider.dart';
import 'package:agua_med/providers/all_user_provider.dart';
import 'package:agua_med/providers/billing_calculate_provider.dart';
import 'package:agua_med/providers/create_owner_provider.dart';
import 'package:agua_med/providers/edit_profile_provider.dart';
import 'package:agua_med/providers/house_provider.dart';
import 'package:agua_med/providers/login_provider.dart';
import 'package:agua_med/providers/meter_camera_provider.dart';
import 'package:agua_med/providers/meter_reading_provider.dart';
import 'package:agua_med/providers/owner_detail_provider.dart';
import 'package:agua_med/providers/reading_bottom_sheet_provider.dart';
import 'package:agua_med/providers/search_house_bill_provider.dart';
import 'package:agua_med/providers/signup_provider.dart';
import 'package:agua_med/providers/town_provider.dart';
import 'package:agua_med/providers/user_home_provider.dart';
import 'package:agua_med/providers/user_provider.dart';
import 'package:agua_med/providers/user_registration_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDOaUoDZWU4WBxGq1NVlmW3L1wf51nPNss",
        projectId: "aqua-med",
        storageBucket: "aqua-med.firebasestorage.app",
        messagingSenderId: "100791974111",
        appId: "1:100791974111:web:96a22e8ee71d7f4d36916a",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Ensure offline mode is enabled
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Unlimited cache size
  );

  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      path: 'assets/translations',
      startLocale: const Locale('es', ''),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const MaterialColor colorCustom = MaterialColor(0xFF156082, {
    50: Color(0xFFE1F5FE),
    100: Color(0xFFB3E5FC),
    200: Color(0xFF81D4FA),
    300: Color(0xFF4FC3F7),
    400: Color(0xFF29B6F6),
    500: Color(0xFF03A9F4),
    600: Color(0xFF039BE5),
    700: Color(0xFF0288D1),
    800: Color(0xFF0277BD),
    900: Color(0xFF01579B),
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: [
        const Breakpoint(start: 0, end: 450, name: MOBILE),
        const Breakpoint(start: 451, end: 800, name: TABLET),
        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<TownProvider>(
            create: (_) => TownProvider(),
          ),
          ChangeNotifierProvider<HouseProvider>(
            create: (_) => HouseProvider(),
          ),
          ChangeNotifierProvider<SignUpProvider>(
            create: (_) => SignUpProvider(),
          ),
          ChangeNotifierProvider<LoginProvider>(
            create: (_) => LoginProvider(),
          ),
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
          ),
          ChangeNotifierProvider<AdminHomeProvider>(
            create: (_) => AdminHomeProvider(),
          ),
          ChangeNotifierProvider<AllUserProvider>(
            create: (_) => AllUserProvider(),
          ),
          ChangeNotifierProvider<CreateOwnerProvider>(
            create: (_) => CreateOwnerProvider(),
          ),
          ChangeNotifierProvider<OwnerDetailProvider>(
            create: (_) => OwnerDetailProvider(),
          ),
          ChangeNotifierProvider<EditProfileProvider>(
            create: (_) => EditProfileProvider(),
          ),
          ChangeNotifierProvider<UserHomeProvider>(
            create: (_) => UserHomeProvider(),
          ),
          ChangeNotifierProvider<UserRegistrationProvider>(
            create: (_) => UserRegistrationProvider(),
          ),
          ChangeNotifierProvider<MeterReadingProvider>(
            create: (_) => MeterReadingProvider(),
          ),
          ChangeNotifierProvider<MeterCameraProvider>(
            create: (_) => MeterCameraProvider(),
          ),
          ChangeNotifierProvider<ReadingBottomSheetProvider>(
            create: (_) => ReadingBottomSheetProvider(),
          ),
          ChangeNotifierProvider<SearchHouseBillProvider>(
            create: (_) => SearchHouseBillProvider(),
          ),
          ChangeNotifierProvider<AdminInvoiceProvider>(
            create: (_) => AdminInvoiceProvider(),
          ),
          ChangeNotifierProvider<BillingCalculateProvider>(
            create: (_) => BillingCalculateProvider(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthenticationBloc>(
                create: (_) => AuthenticationBloc()),
          ],
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) {
              final bool isTabletOrLarger =
                  ResponsiveBreakpoints.of(context).largerThan(TABLET);
              final double appBarFontSize = isTabletOrLarger ? 16 : 14;
              final double textFontSize = isTabletOrLarger ? 15 : 13;

              return Theme(
                data: _buildThemeData(appBarFontSize, textFontSize),
                child: child!,
              );
            },
            debugShowCheckedModeBanner: false,
            title: 'AguaMED',
            theme: _buildThemeData(14, 12),
            home: const SplashScreen(),
            scrollBehavior: AppCustomScrollBehavior(),
          ),
        ),
      ),
    );
  }

  ThemeData _buildThemeData(double appBarFontSize, double textFontSize) {
    return ThemeData(
      fontFamily: 'Lato',
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: whiteColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: whiteColor,
        iconTheme: IconThemeData(color: whiteColor),
        titleTextStyle: TextStyle(
          color: whiteColor,
          fontSize: appBarFontSize,
          fontFamily: 'Lato',
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerColor: secondaryColor,
      dividerTheme: DividerThemeData(color: secondaryColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: p),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: secondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: redColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: redColor),
        ),
        hintStyle: TextStyle(fontSize: textFontSize, color: borderColor),
        labelStyle: TextStyle(fontSize: textFontSize, color: secondaryColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          side: BorderSide(color: primaryColor),
          padding: EdgeInsets.all(p),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: blackColor,
          fontSize: textFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
        ),
        bodyLarge: TextStyle(
          color: blackColor,
          fontSize: textFontSize,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lato',
        ),
        bodyMedium: TextStyle(
          color: blackColor,
          fontSize: textFontSize,
          fontWeight: FontWeight.w400,
          fontFamily: 'Lato',
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: colorCustom)
          .copyWith(secondary: primaryColor),
    );
  }
}

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}


// qibyduke@logsmarter.net (House Owner)
// shanirajput20092000@gmail.com (Inspector)
// hexudoci@thetechnext.net (Town Manager)
// xavada5790@isorax.com (Admin)