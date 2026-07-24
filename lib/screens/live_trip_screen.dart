import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ride_request_service.dart';
import 'trip_completed_screen.dart';

class LiveTripScreen extends StatefulWidget {
  final String rideId;

  final LatLng pickup;
  final LatLng destination;

  final String pickupAddress;
  final String destinationAddress;

  final double distanceKm;
  final String eta;

  final List<LatLng> routePoints;

  final String rideType;
  final double fare;

  const LiveTripScreen({
    super.key,
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
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
  final RideRequestService rideRequestService =
      RideRequestService();

  Timer? tripTimer;
  Timer? driverTimer;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    rideSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    driverLocationSubscription;

  int tripSeconds = 0;

  late double remainingDistance;
  late int remainingMinutes;

  late double originalDistance;

  int currentRouteIndex = 0;

  GoogleMapController? mapController;

  BitmapDescriptor? carIcon;

  String driverName = "Loading...";
String vehicleName = "";
String vehicleNumber = "";
double driverRating = 5.0;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  LatLng driverPosition = const LatLng(
    27.7172,
    85.3240,
  );

  double carRotation = 0;

double _calculateDistanceInMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double earthRadius = 6371000;

  final double dLat =
      (lat2 - lat1) * pi / 180;

  final double dLon =
      (lon2 - lon1) * pi / 180;

  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c =
      2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

  // Prevents duplicate completion.
  bool tripCompleted = false;

  @override
  void initState() {
    super.initState();

    debugPrint(
      "LIVE TRIP STARTED WITH RIDE ID: ${widget.rideId}",
    );

    remainingDistance = widget.distanceKm;
    originalDistance = widget.distanceKm;

    remainingMinutes = int.tryParse(
          widget.eta.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          ),
        ) ??
        0;

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

    listenToRideStatus();

// Start listening to the driver's real GPS location.
listenToDriverLocation();
  }

// =========================================================
// DRIVER COMPLETED THE TRIP
// =========================================================

Future<void> _handleDriverCompletedTrip() async {
  if (tripCompleted) {
    return;
  }

  // Lock immediately to prevent duplicate navigation.
  tripCompleted = true;

  tripTimer?.cancel();
  driverTimer?.cancel();

  await rideSubscription?.cancel();

  debugPrint("====================================");
  debugPrint("DRIVER COMPLETED TRIP");
  debugPrint("RIDE ID: ${widget.rideId}");
  debugPrint("OPENING TRIP COMPLETED SCREEN");
  debugPrint("====================================");

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => TripCompletedScreen(
        rideId: widget.rideId,
        fare: widget.fare,
        distance: originalDistance,
        tripTime: tripTime,
        rideType: widget.rideType,
        pickup: widget.pickupAddress,
        destination: widget.destinationAddress,
      ),
    ),
  );
}


  // =========================================================
  // ONE METHOD FOR ALL TRIP COMPLETION
  // =========================================================

// =========================================================
// LISTEN TO RIDE STATUS FROM DRIVER APP
// =========================================================

void listenToRideStatus() {
  rideSubscription?.cancel();

  rideSubscription = FirebaseFirestore.instance
      .collection("rides")
      .doc(widget.rideId)
      .snapshots()
      .listen(
    (snapshot) {
      if (!snapshot.exists) {
        debugPrint(
          "Ride document not found: ${widget.rideId}",
        );
        return;
      }

      final data = snapshot.data();

      if (data == null) return;

      final String status =
          data["status"]?.toString() ?? "";

      debugPrint(
        "Passenger LiveTrip status: $status",
      );

      if (status == "Completed") {
        _handleDriverCompletedTrip();
      }
    },
    onError: (error) {
      debugPrint(
        "Ride status listener error: $error",
      );
    },
  );
}

// =========================================================
// LISTEN TO REAL DRIVER LOCATION
// =========================================================

Future<void> listenToDriverLocation() async {
  driverLocationSubscription?.cancel();

  try {
    // First get the ride document to find
    // which driver accepted this ride.
    final rideSnapshot = await FirebaseFirestore.instance
        .collection("rides")
        .doc(widget.rideId)
        .get();

    if (!rideSnapshot.exists) {
      debugPrint(
        "Cannot listen to driver location: ride not found.",
      );
      return;
    }

    final rideData = rideSnapshot.data();

    if (rideData == null) {
      debugPrint(
        "Cannot listen to driver location: ride data is empty.",
      );
      return;
    }

    final String driverId =
        rideData["driverId"]?.toString() ?? "";

    if (driverId.isEmpty) {
      debugPrint(
        "Cannot listen to driver location: no driver assigned.",
      );
      return;
    }

    debugPrint(
      "Listening to real driver location: $driverId",
    );

    driverLocationSubscription =
        FirebaseFirestore.instance
            .collection("drivers")
            .doc(driverId)
            .snapshots()
            .listen(
      (driverSnapshot) {
        if (!driverSnapshot.exists) {
          debugPrint(
            "Driver profile not found: $driverId",
          );
          return;
        }

        final driverData = driverSnapshot.data();

if (driverData == null) {
  return;
}

final data = driverData;

    driverName =
    data["name"]?.toString() ?? "Driver";

vehicleName =
    data["vehicleName"]?.toString() ?? "";

vehicleNumber =
    data["vehicleNumber"]?.toString() ?? "";

driverRating =
    (data["rating"] as num?)?.toDouble() ?? 5.0;

        if (driverData == null) {
          return;
        }

        final double? latitude =
            (driverData["latitude"] as num?)
                ?.toDouble();

        final double? longitude =
            (driverData["longitude"] as num?)
                ?.toDouble();

        if (latitude == null ||
            longitude == null) {
          debugPrint(
            "Driver location is unavailable.",
          );
          return;
        }

        final LatLng newDriverPosition = LatLng(
          latitude,
          longitude,
        );

        debugPrint(
          "Real driver location: "
          "$latitude, $longitude",
        );

        // Calculate straight-line remaining distance
// from the real driver position to the destination.
final double remainingDistanceInMeters =
    _calculateDistanceInMeters(
  newDriverPosition.latitude,
  newDriverPosition.longitude,
  widget.destination.latitude,
  widget.destination.longitude,
);

final double newRemainingDistance =
    remainingDistanceInMeters / 1000;

// Temporary ETA calculation using an average
// driving speed of 30 km/h.
final int newRemainingMinutes =
    newRemainingDistance <= 0.05
        ? 0
        : max(
            1,
            ((newRemainingDistance / 30) * 60)
                .ceil(),
          );

        // Calculate the direction from the old
// GPS position to the new GPS position.
if (driverPosition.latitude !=
        newDriverPosition.latitude ||
    driverPosition.longitude !=
        newDriverPosition.longitude) {
  final double dx =
      newDriverPosition.longitude -
      driverPosition.longitude;

  final double dy =
      newDriverPosition.latitude -
      driverPosition.latitude;

  carRotation =
      atan2(dx, dy) * 180 / pi;
}

        if (!mounted || tripCompleted) {
          return;
        }

        setState(() {
  driverPosition = newDriverPosition;

  remainingDistance = newRemainingDistance;
  remainingMinutes = newRemainingMinutes;

  markers.removeWhere(
            (marker) =>
                marker.markerId.value == "driver",
          );

          markers.add(
            Marker(
              markerId: const MarkerId("driver"),
              position: driverPosition,
              rotation: carRotation,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              icon: carIcon ??
                  BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(
                title: "Driver",
              ),
            ),
          );
        });
        mapController?.animateCamera(
  CameraUpdate.newCameraPosition(
    CameraPosition(
      target: newDriverPosition,
      zoom: 17,
      tilt: 45,
      bearing: carRotation,
    ),
  ),
);
      },
      onError: (error) {
        debugPrint(
          "Driver location listener error: $error",
        );
      },
    );
  } catch (e) {
    debugPrint(
      "Error starting driver location listener: $e",
    );
  }
}

  Future<void> finishTrip() async {
    // Stop if trip was already completed.
    if (tripCompleted) {
      debugPrint(
        "finishTrip ignored because trip is already completed.",
      );
      return;
    }

    // Lock immediately to prevent another timer/button call.
    tripCompleted = true;

    tripTimer?.cancel();
    driverTimer?.cancel();

    debugPrint("====================================");
    debugPrint("COMPLETING RIDE");
    debugPrint("RIDE ID: ${widget.rideId}");
    debugPrint("====================================");

    try {
      // Update the SAME original Firestore ride document.
      await rideRequestService.completeRide(
        widget.rideId,
      );

      debugPrint(
        "RIDE COMPLETED SUCCESSFULLY: ${widget.rideId}",
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripCompletedScreen(
            rideId: widget.rideId,
            fare: widget.fare,
            distance: originalDistance,
            tripTime: tripTime,
            rideType: widget.rideType,
            pickup: widget.pickupAddress,
            destination: widget.destinationAddress,
          ),
        ),
      );
    } catch (e) {
      debugPrint("ERROR COMPLETING RIDE: $e");

      // Allow retry if Firestore update failed.
      tripCompleted = false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not complete ride: $e",
          ),
        ),
      );
    }
  }

  // =========================================================
  // TRIP TIMER
  // =========================================================

void startTripTimer() {
  tripTimer?.cancel();

  tripTimer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      if (!mounted || tripCompleted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Only update the real elapsed trip time.
        tripSeconds++;
      });
    },
  );
}
  // =========================================================
  // LOAD CAR ICON
  // =========================================================

  Future<void> loadCarIcon() async {
    try {
      carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(
          size: Size(60, 60),
        ),
        "assets/images/car.png",
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("CAR ICON ERROR: $e");
    }
  }

  // =========================================================
  // DRIVER MOVEMENT
  // =========================================================

  void startDriverMovement() {
    driverTimer?.cancel();

    if (widget.routePoints.isEmpty) {
      debugPrint("Route points are empty.");
      return;
    }

    // Start from first actual route point.
    driverPosition = widget.routePoints.first;

    driverTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (!mounted || tripCompleted) {
          timer.cancel();
          return;
        }

        if (currentRouteIndex >=
    widget.routePoints.length) {
  timer.cancel();

  debugPrint(
    "Simulated route finished. Waiting for driver to complete trip.",
  );

  return;
}

        final nextPoint =
            widget.routePoints[currentRouteIndex];

        final dx =
            nextPoint.longitude - driverPosition.longitude;

        final dy =
            nextPoint.latitude - driverPosition.latitude;

        carRotation =
            atan2(dx, dy) * 180 / pi + 180;

        driverPosition = nextPoint;

        currentRouteIndex++;

        if (!mounted) return;

        setState(() {
          markers.removeWhere(
            (marker) =>
                marker.markerId.value == "driver",
          );

          markers.add(
            Marker(
              markerId: const MarkerId("driver"),
              position: driverPosition,
              rotation: carRotation,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              icon: carIcon ??
                  BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(
                title: "Driver",
              ),
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

  // =========================================================
  // TRIP TIME
  // =========================================================

  String get tripTime {
    final minutes = (tripSeconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (tripSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return "$minutes:$seconds";
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
void dispose() {
  tripTimer?.cancel();
  driverTimer?.cancel();
  rideSubscription?.cancel();
  driverLocationSubscription?.cancel();
  mapController?.dispose();

  super.dispose();
}

  // =========================================================
  // UI
  // =========================================================

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

                if (widget.routePoints.isNotEmpty) {
                  driverPosition =
                      widget.routePoints.first;
                }

                setState(() {
                  markers.removeWhere(
                    (marker) =>
                        marker.markerId.value ==
                        "driver",
                  );

                  markers.add(
                    Marker(
                      markerId:
                          const MarkerId("driver"),
                      position: driverPosition,
                      icon: carIcon ??
                          BitmapDescriptor
                              .defaultMarker,
                      infoWindow: const InfoWindow(
                        title: "Driver",
                      ),
                    ),
                  );
                });
              },
              markers: markers,
              polylines: polylines,
              initialCameraPosition: CameraPosition(
                target: widget.routePoints.isNotEmpty
                    ? widget.routePoints.first
                    : widget.pickup,
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
                Card(
  elevation: 2,
  child: ListTile(
    leading: const CircleAvatar(
      radius: 28,
      child: Icon(Icons.person),
    ),
    title: Text(
      driverName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(vehicleName),
        Text(vehicleNumber),
      ],
    ),
    trailing: Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.star,
          color: Colors.orange,
        ),
        Text(driverRating.toString()),
      ],
    ),
  ),
),
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
                  leading:
                      const Icon(Icons.access_time),
                  title: const Text("ETA"),
                  trailing: Text(
                    "$remainingMinutes min",
                  ),
                ),

                const SizedBox(height: 20),

                Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  ),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.blue.shade200,
    ),
  ),
  child: const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.directions_car,
        color: Colors.blue,
      ),
      SizedBox(width: 10),
      Flexible(
        child: Text(
          "Trip in progress — waiting for driver to complete the ride",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
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