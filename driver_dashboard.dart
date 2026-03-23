import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ ADDED

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {

  final FlutterBackgroundService service = FlutterBackgroundService();

  String lat = "0";
  String long = "0";

  bool tripStarted = false;

  StreamSubscription<Position>? positionStream;

  String driverId = "";
  String driverName = "";
  String driverMobile = "";
  String driverBusNo = "";
  String driverRoute = "";

  // ✅ AD VARIABLES
  BannerAd? bannerAd;
  bool isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    loadDriverData();
    loadAd(); // ✅ ADDED
  }

  // ================= LOAD AD =================
  void loadAd() {

    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-9332148976634523/7351534762", // add  ID
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Ad failed: $error");
        },
      ),
      request: const AdRequest(),
    );

    bannerAd!.load();
  }

  // ================= LOAD DRIVER DATA =================
  Future<void> loadDriverData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      driverId = prefs.getString('driverId') ?? "";
      driverName = prefs.getString('name') ?? "";
      driverMobile = prefs.getString('mobile') ?? "";
      driverBusNo = prefs.getString('busNo') ?? "";
      driverRoute = prefs.getString('route') ?? "";
    });

    await checkLocationPermission();
  }

  // ================= LOCATION PERMISSION =================
  Future<void> checkLocationPermission() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
  }

  // ================= START LOCATION STREAM =================
  void startLocationUpdates() {

    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {

      if (!tripStarted) return;

      updateLocation(position);

    });
  }

  // ================= FIRESTORE UPDATE =================
  Future<void> updateLocation(Position position) async {

    lat = position.latitude.toString();
    long = position.longitude.toString();

    try {

      await FirebaseFirestore.instance
          .collection("bus_location")
          .doc("bus$driverBusNo")
          .set({

        "driverId": driverId,
        "driverName": driverName,
        "driverMobile": driverMobile,
        "busNo": driverBusNo,
        "route": driverRoute,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "tripStatus": tripStarted ? "running" : "stopped",
        "timestamp": FieldValue.serverTimestamp(),

      }, SetOptions(merge: true));

    } catch (e) {

      print("Firestore error $e");

    }

    setState(() {});
  }

  // ================= START TRIP =================
  Future<void> startTrip() async {

    await checkLocationPermission();

    if (driverBusNo.isEmpty) {
      print("Bus number missing");
      return;
    }

    tripStarted = true;

    bool isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }

    service.invoke("setDriverData", {
      "driverId": driverId,
      "driverName": driverName,
      "driverBusNo": driverBusNo,
      "tripStarted": true,
    });

    startLocationUpdates();

    setState(() {});
  }

  // ================= STOP TRIP =================
  Future<void> stopTrip() async {

    tripStarted = false;

    positionStream?.cancel();

    service.invoke("stopService");

    try {

      await FirebaseFirestore.instance
          .collection("bus_location")
          .doc("bus$driverBusNo")
          .update({

        "tripStatus": "stopped",
        "timestamp": FieldValue.serverTimestamp(),

      });

    } catch (e) {

      print("Stop trip error $e");

    }

    setState(() {});
  }

  @override
  void dispose() {

    positionStream?.cancel();
    bannerAd?.dispose(); // ✅ ADDED

    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      // ✅ BANNER AD
      bottomNavigationBar: isAdLoaded
          ? SizedBox(
              height: bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: bannerAd!),
            )
          : null,

      body: SingleChildScrollView(

        child: Column(

          children: [

            Container(

              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 25),

              decoration: const BoxDecoration(

                color: Color(0xff0d6efd),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),

              ),

              child: Column(

                children: [

                  const Text(
                    "SATPUDA COLLEGE OF ENGINEERING AND POLYTECHNIC BALAGHAT [MP]",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Driver Dashboard",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  )

                ],

              ),

            ),

            const SizedBox(height: 25),

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 16),

              child: Column(

                children: [

                  buildBox("Name", driverName),
                  buildBox("Mobile", driverMobile),
                  buildBox("Bus No", driverBusNo),
                  buildBox("Route", driverRoute),

                  const SizedBox(height: 10),

                  buildLocationBox(),

                  const SizedBox(height: 25),

                  Row(

                    children: [

                      Expanded(

                        child: ElevatedButton(

                          onPressed: tripStarted ? null : startTrip,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0d6efd),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),

                          child: const Text("Start Trip"),

                        ),

                      ),

                      const SizedBox(width: 15),

                      Expanded(

                        child: ElevatedButton(

                          onPressed: tripStarted ? stopTrip : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),

                          child: const Text("Stop Trip"),

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 20),

                  Container(

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: tripStarted
                          ? Colors.green.shade100
                          : Colors.red.shade100,

                      borderRadius: BorderRadius.circular(10),

                    ),

                    child: Text(

                      tripStarted ? "Trip Running" : "Trip Stopped",

                      style: TextStyle(
                        color: tripStarted ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),

                    ),

                  ),

                  const SizedBox(height: 40),

                ],

              ),

            )

          ],

        ),

      ),

    );

  }

  Widget buildBox(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title -",
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLocationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xff0d6efd)),
              SizedBox(width: 6),
              Text(
                "Current Location",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Latitude"),
              Text(lat,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Longitude"),
              Text(long,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}