import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'live_trip_screen.dart';

class DriverFoundScreen extends StatefulWidget {
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

  const DriverFoundScreen({
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
  State<DriverFoundScreen> createState() => _DriverFoundScreenState();
}

class _DriverFoundScreenState extends State<DriverFoundScreen> {
  bool driverArrived = false;

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection("rides")
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;

      if (data["status"] == "Arrived") {
        if (!mounted) return;

        setState(() {
          driverArrived = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Your driver has arrived!"),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Found"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Ram Sharma",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                "⭐ 4.9",
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.directions_car),
                  ),
                  title: Text(
                    "Toyota Prius",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text("BA 2 PA 1234"),
                  trailing: Text(
                    "⭐ 4.9",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text("Pickup"),
                  subtitle: Text(widget.pickupAddress),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Destination"),
                  subtitle: Text(widget.destinationAddress),
                ),
              ),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(
                    driverArrived
                        ? Icons.check_circle
                        : Icons.location_on,
                    color:
                        driverArrived ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    driverArrived
                        ? "Driver has arrived!"
                        : "Driver is on the way",
                  ),
                  subtitle: Text(
                    driverArrived
                        ? "Your driver is waiting at the pickup point."
                        : "ETA: ${widget.eta}",
                  ),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_taxi),
                  title: Text(widget.rideType),
                  trailing: Text(
                    "NPR ${widget.fare.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Ride"),
                  onPressed: driverArrived
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveTripScreen(
  rideId: widget.rideId,
  pickup: widget.pickup,
  destination: widget.destination,
  pickupAddress: widget.pickupAddress,
  destinationAddress: widget.destinationAddress,
  distanceKm: widget.distanceKm,
  eta: widget.eta,
  routePoints: widget.routePoints,
  rideType: widget.rideType,
  fare: widget.fare,
),
                            ),
                          );
                        }
                      : null,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text("Call Driver"),
                  onPressed: () {},
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat"),
                  onPressed: () {},
                ),
              ),

              const SizedBox(height: 10),

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
                  child: const Text("Cancel Ride"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}