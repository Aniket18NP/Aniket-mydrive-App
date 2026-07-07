import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'live_trip_screen.dart';

class DriverFoundScreen extends StatelessWidget {
  final LatLng pickup;
  final LatLng destination;
  final double distanceKm;
  final String eta;
  final List<LatLng> routePoints;

  // NEW
  final String rideType;
  final double fare;

  const DriverFoundScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    required this.eta,
    required this.routePoints,

    // NEW
    required this.rideType,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Found"),
        centerTitle: true,
      ),
      body: Padding(
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
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                title: const Text("Driver is on the way"),
                subtitle: Text("ETA: $eta"),
              ),
            ),

            // NEW CARD
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_taxi),
                title: Text(rideType),
                trailing: Text(
                  "NPR ${fare.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Ride"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTripScreen(
                        pickup: pickup,
                        destination: destination,
                        distanceKm: distanceKm,
                        eta: eta,
                        routePoints: routePoints,

                        // NEW
                        rideType: rideType,
                        fare: fare,
                      ),
                    ),
                  );
                },
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
    );
  }
}