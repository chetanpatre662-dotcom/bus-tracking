import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveBusLocation extends StatefulWidget {
  @override
  _LiveBusLocationState createState() => _LiveBusLocationState();
}

class _LiveBusLocationState extends State<LiveBusLocation> {

  final Completer<GoogleMapController> _controller = Completer();

  Map<MarkerId, Marker> markers = {};

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(21.767917, 80.0464217), // default center
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    listenBusLocations();
  }

  void listenBusLocations() {

    FirebaseFirestore.instance
        .collection('bus_location')
        .snapshots()
        .listen((snapshot) {

      for (var doc in snapshot.docs) {

        double lat = doc['latitude'];
        double lng = doc['longitude'];
        String busNo = doc['busNo'];

        final markerId = MarkerId(doc.id);

        final marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: "Bus $busNo",
            snippet: doc['driverName'] ?? "",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        setState(() {
          markers[markerId] = marker;
        });

        moveCamera(lat, lng);
      }
    });
  }

  Future<void> moveCamera(double lat, double lng) async {

    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Live Bus Location"),
      ),

      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: Set<Marker>.of(markers.values),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}