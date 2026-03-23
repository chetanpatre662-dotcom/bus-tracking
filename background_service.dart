import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// ================= INITIALIZE SERVICE =================
Future<void> initializeService() async {

  final service = FlutterBackgroundService();

  await service.configure(

    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceNotificationId: 888,
    ),

    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),

  );
}

/// ================= iOS BACKGROUND =================
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  return true;
}

/// ================= MAIN SERVICE =================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  String driverId = "";
  String driverName = "";
  String driverBusNo = "";
  bool tripStarted = false;

  Timer? timer;

  /// ANDROID FOREGROUND SERVICE
  if (service is AndroidServiceInstance) {

    service.setForegroundNotificationInfo(
      title: "Bus Tracking Running",
      content: "Driver location updating...",
    );

    /// STOP SERVICE
    service.on("stopService").listen((event) {

      timer?.cancel();
      service.stopSelf();

    });

  }

  /// RECEIVE DRIVER DATA FROM DRIVER DASHBOARD
  service.on("setDriverData").listen((event) {

    driverId = event?["driverId"] ?? "";
    driverName = event?["driverName"] ?? "";
    driverBusNo = event?["driverBusNo"] ?? "";
    tripStarted = event?["tripStarted"] ?? false;

    print("Driver Data Received : Bus $driverBusNo");

    /// LOCATION TIMER
    timer ??= Timer.periodic(const Duration(seconds: 5), (timer) async {

  if (!tripStarted || driverBusNo.isEmpty) return;

  try {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("Location service disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission denied forever");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await FirebaseFirestore.instance
        .collection("bus_location")
        .doc("bus$driverBusNo")
        .set({

      "driverId": driverId,
      "driverName": driverName,
      "busNo": driverBusNo,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "tripStatus": "running",
      "timestamp": FieldValue.serverTimestamp(),

    }, SetOptions(merge: true));

    print("BG Location Updated bus$driverBusNo");

  } catch (e) {

    print("BG Error: $e");

  }

  });

  });

}