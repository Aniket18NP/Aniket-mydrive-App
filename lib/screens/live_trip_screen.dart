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

  int tripSeconds = 0;

  late double remainingDistance;
  late int remainingMinutes;

  late double originalDistance;

  int currentRouteIndex = 0;

  GoogleMapController? mapController;

  BitmapDescriptor? carIcon;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  LatLng driverPosition = const LatLng(
    27.7172,
    85.3240,
  );

  double carRotation = 0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startDriverMovement();
    });
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
          tripSeconds++;

          if (remainingDistance > 0) {
            remainingDistance -= 0.01;

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