import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'role_selection_screen.dart';
import 'driver_dashboard.dart';
import 'student_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  late Animation<Offset> phoneSlide;
  late Animation<double> phoneRipple;

  late Animation<Offset> busSlide;

  late Animation<Offset> pinDrop;
  late Animation<double> pinRipple;

  late Animation<double> fadeText;

  String scepText = "";
  String groupText = "";

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    /// PHONE (Right → Center)
    phoneSlide = Tween<Offset>(
      begin: const Offset(2, 0),
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.1, 0.3, curve: Curves.easeOut),
    ));

    /// PHONE RIPPLE (CALLING)
    phoneRipple = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.3, 0.45)),
    );

    /// BUS (Left → Phone)
    busSlide = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: const Offset(-0.1, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
    ));

    /// PIN DROP
    pinDrop = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.6, 0.75, curve: Curves.bounceOut),
    ));

    /// PIN RIPPLE
    pinRipple = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.7, 0.85)),
    );

    /// FINAL TEXT FADE
    fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.85, 1)),
    );

    startAnimation();
    _loadInterstitialAd();
    navigateNextWithAd();
  }

  Future<void> typeText(String text, Function(String) setter) async {
    String current = "";
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      current += text[i];
      if (mounted) setState(() => setter(current));
    }
  }

  void startAnimation() async {
    controller.forward();

    await Future.delayed(const Duration(seconds: 5));

    await typeText("SCEP BUS", (v) => scepText = v);
    await typeText("SATPUDA GROUP", (v) => groupText = v);
  }

  /// ===============================
  /// LOAD INTERSTITIAL AD
  /// ===============================
  void _loadInterstitialAd() {
    InterstitialAd.load(
     adUnitId: 'ca-app-pub-9332148976634523/5341983941',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          _isAdLoaded = false;
          debugPrint('InterstitialAd failed to load: $err');
        },
      ),
    );
  }

  /// ===============================
  /// NAVIGATE AFTER SPLASH + SHOW AD
  /// ===============================
  void navigateNextWithAd() async {
    await Future.delayed(const Duration(seconds: 8)); // wait for animation

    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool loggedIn = prefs.getBool("loggedIn") ?? false;
    String? role = prefs.getString("role");

    if (!mounted) return;

    // SHOW INTERSTITIAL AD IF LOADED
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _goToDashboard(loggedIn, role);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _goToDashboard(loggedIn, role);
        },
      );
      _interstitialAd!.show();
    } else {
      // IF AD NOT LOADED, DIRECTLY GO TO DASHBOARD
      _goToDashboard(loggedIn, role);
    }
  }

  void _goToDashboard(bool loggedIn, String? role) {
    Widget screen;

    if (!loggedIn) {
      screen = const RoleSelectionScreen();
    } else {
      if (role == "Driver") screen = const DriverDashboard();
      else screen = const StudentDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Stack(
            children: [

              /// BACKGROUND
              Positioned.fill(
                child: Image.asset(
                  "assets/background.jpeg",
                  fit: BoxFit.cover,
                ),
              ),

              /// PHONE + RIPPLE
              Positioned(
                right: 25.w,
                bottom: 130.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    /// PHONE RIPPLE
                    if (phoneRipple.value > 0)
                      Container(
                        width: 140 * phoneRipple.value,
                        height: 140 * phoneRipple.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(
                              0.3 * (1 - phoneRipple.value)),
                        ),
                      ),

                    SlideTransition(
                      position: phoneSlide,
                      child: Image.asset(
                        "assets/phone.png",
                        width: 260.w,
                      ),
                    ),
                  ],
                ),
              ),

              /// BUS
              Positioned(
                left: 25.w,
                bottom: 120.h,
                child: SlideTransition(
                  position: busSlide,
                  child: Image.asset(
                    "assets/bus.png",
                    width: 300.w,
                  ),
                ),
              ),

              /// PIN + TEXT
              Positioned(
                top: 100.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [

                    /// PIN DROP
                    SlideTransition(
                      position: pinDrop,
                      child: Image.asset(
                        "assets/pin.png",
                        width: 40.w,
                      ),
                    ),

                    /// PIN RIPPLE
                    if (pinRipple.value > 0)
                      Container(
                        width: 80 * pinRipple.value,
                        height: 80 * pinRipple.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(
                              0.3 * (1 - pinRipple.value)),
                        ),
                      ),

                    SizedBox(height: 10.h),

                    /// TYPING TEXT
                    Text(
                      scepText,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xff1F4FA3),
                      ),
                    ),

                    Text(
                      groupText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff2C7BC9),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    /// FINAL TEXT
                    FadeTransition(
                      opacity: fadeText,
                      child: Column(
                        children: [
                          Text(
                            "TRACK YOUR BUS",
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xff1F4FA3),
                            ),
                          ),
                          Text(
                            "IN REAL-TIME",
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xff1F4FA3),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              /// CREDIT
              Positioned(
                bottom: 20.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "by Chetan Patre",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}