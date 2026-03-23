import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'background_service.dart';
import 'splash_screen.dart';
import 'driver_dashboard.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'role_selection_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  /// FIREBASE INIT
  await Firebase.initializeApp();

  /// BACKGROUND LOCATION SERVICE
  await initializeService();
  
  await MobileAds.instance.initialize();
 

  /// CHECK LOGIN STATUS
  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool loggedIn = prefs.getBool("loggedIn") ?? false;
  String? role = prefs.getString("role");

  runApp(MyApp(
    loggedIn: loggedIn,
    role: role,
  ));
}

class MyApp extends StatelessWidget {

  final bool loggedIn;
  final String? role;

  const MyApp({
    super.key,
    required this.loggedIn,
    this.role,
  });

  @override
  Widget build(BuildContext context) {

    return ScreenUtilInit(

      designSize: const Size(360, 690),

      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {

        return MaterialApp(

          debugShowCheckedModeBanner: false,
          title: 'SCEP Bus Tracker',

          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),

          /// START SCREEN
          home: const SplashScreen(),

          /// ROUTES
          routes: {

            '/driver': (context) => const DriverDashboard(),

            '/student': (context) => const StudentDashboard(),

            '/admin': (context) => AdminDashboard(),

            '/role_selection': (context) => const RoleSelectionScreen(),

          },

        );
      },
    );
  }
}