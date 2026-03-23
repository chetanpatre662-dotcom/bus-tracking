import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ FIX 1: ADD THIS IMPORT (NEW)
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // 🔥 YE MISSING THA

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  GoogleMapController? mapController;
  bool isFullScreen = false;

  String selectedBus = "bus1";
  String studentName = "";
  String studentMobile = "";

  String driverName = "";
  String driverMobile = "";
  bool tripActive = false;

  LatLng busLocation = const LatLng(20.5937, 78.9629);

  Marker? busMarker;
  Polyline? busPolyline;
  BitmapDescriptor? busIcon;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? busSub;

  List<LatLng> busTrail = [];

  /// 🔥 ADS
  late BannerAd bannerAd;
  bool isAdLoaded = false;
  Timer? adTimer;

  @override
  void initState() {
    super.initState();
    loadStudentData();
    loadAd();

    adTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        bannerAd.load();
      }
    });
  }

  void loadAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-9332148976634523/7351534762",
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<BitmapDescriptor> getSmallBusIcon() async {
    final ByteData data = await rootBundle.load('assets/icons/bus.png');

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 150,
      targetHeight: 150,
    );

    final frame = await codec.getNextFrame();
    final byteData =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> loadStudentData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? busNo = prefs.getString('busNo');

    setState(() {
      studentName = prefs.getString('name') ?? "";
      studentMobile = prefs.getString('mobile') ?? "";
      selectedBus = "bus${busNo ?? "1"}";
    });

    startListeningBus(selectedBus);
  }

  void startListeningBus(String busId) {
    busSub?.cancel();
    busTrail.clear();

    busSub = FirebaseFirestore.instance
        .collection('bus_location')
        .doc(busId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();

        driverName = data['driverName'] ?? "";
        driverMobile = data['driverMobile'] ?? "";
        tripActive = data['tripActive'] ?? false;

        final newLocation = LatLng(lat, lng);

        busTrail.add(newLocation);
        if (busTrail.length > 50) busTrail.removeAt(0);

        animateMarker(busLocation, newLocation);

        setState(() {
          busPolyline = Polyline(
            polylineId: PolylineId(busId),
            points: busTrail,
            color: const Color(0xff2962FF),
            width: 5,
          );
        });

        mapController?.animateCamera(
          CameraUpdate.newLatLng(newLocation),
        );

        busLocation = newLocation;
      }
    });
  }

  void animateMarker(LatLng from, LatLng to) async {
    const steps = 30;
    final latStep = (to.latitude - from.latitude) / steps;
    final lngStep = (to.longitude - from.longitude) / steps;

    for (int i = 1; i <= steps; i++) {
      final nextPos = LatLng(
        from.latitude + latStep * i,
        from.longitude + lngStep * i,
      );

      setState(() {
        busMarker = Marker(
          markerId: MarkerId(selectedBus),
          position: nextPos,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: selectedBus.toUpperCase()),
          icon: busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });

      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void onBusChanged(String? newBus) {
    if (newBus != null && newBus != selectedBus) {
      setState(() {
        selectedBus = newBus;
      });
      startListeningBus(selectedBus);
    }
  }

  @override
  void dispose() {
    busSub?.cancel();
    mapController?.dispose();
    bannerAd.dispose();
    adTimer?.cancel();
    super.dispose();
  }

  Future<bool> onWillPop() async {
    if (isFullScreen) {
      setState(() {
        isFullScreen = false;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FA),
        body: SafeArea(
          child: Stack(
            children: [
              /// MAIN CONTENT
              SingleChildScrollView(

                // ✅ FIX 2: ADD THIS (scroll issue fix)
                physics: isFullScreen
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),

                padding: EdgeInsets.only(bottom: 80.h),
                child: Column(
                  children: [
                    if (!isFullScreen)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 16.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xff2962FF),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(18.r),
                            bottomRight: Radius.circular(18.r),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "SATPUDA COLLEGE OF ENGINEERING AND POLYTECHNIC BALAGHAT",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: isFullScreen ? 0 : 12.h),

                    if (!isFullScreen)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            buildInfoCard(Icons.person, "Name", studentName),
                            buildInfoCard(Icons.phone, "Mobile", studentMobile),

                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: DropdownButton<String>(
                                value: selectedBus,
                                underline: const SizedBox(),
                                isExpanded: true,
                                onChanged: onBusChanged,
                                items: List.generate(15, (index) {
                                  return DropdownMenuItem(
                                    value: 'bus${index + 1}',
                                    child: Center(
                                      child: Text("Bus ${index + 1}"),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// MAP
                    Container(
                      height: isFullScreen
                          ? screenHeight * 0.85
                          : screenHeight * 0.45,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: busLocation,
                                zoom: 15,
                              ),

                              // ✅ FIX 3: MAIN MAP FIX
                              gestureRecognizers: <
                                  Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },

                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,

                              markers:
                                  busMarker != null ? {busMarker!} : {},
                              polylines:
                                  busPolyline != null ? {busPolyline!} : {},
                              myLocationEnabled: true,
                              zoomControlsEnabled: true,
                              onMapCreated: (controller) async {
                                mapController = controller;
                                busIcon = await getSmallBusIcon();
                                setState(() {});
                              },
                            ),
                          ),

                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              child: Icon(
                                isFullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                size: 20.sp,
                                color: const Color(0xff2962FF),
                              ),
                              onPressed: () {
                                setState(() {
                                  isFullScreen = !isFullScreen;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// DRIVER INFO
                    if (!isFullScreen)
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22.r,
                              backgroundColor: const Color(0xff2962FF),
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 20.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(driverName),
                                  Text(driverMobile),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.call,
                                  color: Colors.green),
                              onPressed: () async {
                                final Uri phoneUri =
                                    Uri(scheme: 'tel', path: driverMobile);
                                await launchUrl(phoneUri);
                              },
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              /// 🔥 AD
              if (isAdLoaded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    width: bannerAd.size.width.toDouble(),
                    height: bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: bannerAd),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2962FF), size: 20.sp),
          SizedBox(width: 12.w),
          Text("$title : "),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}