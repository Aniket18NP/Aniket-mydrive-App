import 'dart:async';
import 'dart:math';

import 'trip_completed_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTripScreen extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final double distanceKm;
  final String eta;
  final List<LatLng> routePoints;

  final String rideType;
  final double fare;

  const LiveTripScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    required this.eta,
    required this.routePoints,
    required this.rideType,
    required this.fare,
  });

  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> {
  Timer? tripTimer;
  int tripSeconds = 0;

  late double remainingDistance;

late int remainingMinutes;

late double originalDistance;
late int originalMinutes;

int currentRouteIndex = 0;

  GoogleMapController? mapController;

  LatLng carPosition = const LatLng(
  27.7172,
  85.3240,
);

double carRotation = 0;


  BitmapDescriptor? carIcon;

final Set<Marker> markers = {};

final Set<Polyline> polylines = {};

Timer? driverTimer;

LatLng driverPosition = const LatLng(
  27.7172,
  85.3240,
);



LatLng get destination => widget.destination;

  @override
void initState() {
  super.initState();

  print("Distance received: ${widget.distanceKm}");
print("ETA received: ${widget.eta}");

  remainingDistance = widget.distanceKm;

remainingMinutes = int.tryParse(
  widget.eta.replaceAll(RegExp(r'[^0-9]'), ''),
) ?? 0;

originalDistance = widget.distanceKm;
originalMinutes = remainingMinutes;

polylines.add(
  Polyline(
    polylineId: const PolylineId("tripRoute"),
    points: widget.routePoints,
    color: Colors.blue,
    width: 6,
  ),
);

 startTripTimer();
loadCarIcon();

WidgetsBinding.instance.addPostFrameCallback((_) {
  startDriverMovement();
});
}

  void startTripTimer() {
  tripTimer?.cancel();

  tripTimer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      setState(() {
        tripSeconds++;
        

        if (remainingDistance > 0) {
          remainingDistance -= 0.01;

          if (remainingDistance <= 0) {
  tripTimer?.cancel();

  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => TripCompletedScreen(
  fare: widget.fare,
  distance: originalDistance,
  tripTime: tripTime,
  rideType: widget.rideType,
  pickup: "Current Location",
  destination: "Destination",
),
  ),
);
}

          if (remainingDistance < 0) {
            remainingDistance = 0;
          }
        }

        if (tripSeconds % 30 == 0 &&
            remainingMinutes > 0) {
          remainingMinutes--;
        }
      });
    },
  );
}

  Future<void> loadCarIcon() async {
  carIcon = await BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(60, 60)),
    "assets/images/car.png",
  );

  setState(() {});
}

void startDriverMovement() {
  driverTimer?.cancel();

  driverTimer = Timer.periodic(
    const Duration(milliseconds: 500),
    (timer) {
      if (currentRouteIndex >= widget.routePoints.length) {
        timer.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripCompletedScreen(
  fare: widget.fare,
  distance: originalDistance,
  tripTime: tripTime,
  rideType: widget.rideType,
  pickup: "Current Location",
  destination: "Destination",
),
          ),
        );

        return;
      }

      final nextPoint = widget.routePoints[currentRouteIndex];

      final dx = nextPoint.longitude - driverPosition.longitude;
      final dy = nextPoint.latitude - driverPosition.latitude;

      carRotation = atan2(dx, dy) * 180 / pi + 180;

      driverPosition = nextPoint;

      currentRouteIndex++;

      setState(() {
        markers.removeWhere(
          (m) => m.markerId.value == "driver",
        );

        markers.add(
          Marker(
            markerId: const MarkerId("driver"),
            position: driverPosition,
            rotation: carRotation,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon: carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "Driver"),
          ),
        );
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: driverPosition,
            zoom: 17,
            tilt: 45,
            bearing: carRotation,
          ),
        ),
      );
    },
  );
}
  String get tripTime {
    final minutes = (tripSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (tripSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  double calculateFare(double distance) {
  return 80 + (distance * 25);
}

  @override
  void dispose() {
    tripTimer?.cancel();
driverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip in Progress"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
 onMapCreated: (controller) {
  mapController = controller;

  markers.add(
    Marker(
      markerId: const MarkerId("driver"),
      position: driverPosition,
      icon: carIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: const InfoWindow(
        title: "Driver",
      ),
    ),
  );
},

  markers: markers,

  polylines: polylines,

  initialCameraPosition: const CameraPosition(
    target: LatLng(27.7172, 85.3240),
    zoom: 15,
  ),


  myLocationEnabled: true,
  myLocationButtonEnabled: true,
  zoomControlsEnabled: false,
  mapType: MapType.normal,
),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text("Trip Time"),
                  trailing: Text(
                    tripTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
               ListTile(
  leading: const Icon(Icons.route),
  title: const Text("Distance Left"),
  trailing: Text(
    "${remainingDistance.toStringAsFixed(2)} km",
  ),
),

               ListTile(
  leading: const Icon(Icons.access_time),
  title: const Text("ETA"),
  trailing: Text(
    "$remainingMinutes min",
  ),
),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("End Ride"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}