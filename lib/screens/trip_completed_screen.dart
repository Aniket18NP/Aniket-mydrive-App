import 'package:flutter/material.dart';

import '../data/ride_data.dart';
import '../models/ride_history.dart';

import 'payment_screen.dart';

class TripCompletedScreen extends StatelessWidget {
  final double fare;
  final double distance;
  final String tripTime;
  final String rideType;
final String pickup;
final String destination;

  const TripCompletedScreen({
    super.key,
    required this.fare,
    required this.distance,
    required this.tripTime,
    required this.rideType,
    required this.pickup,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    if (RideData.rides.isEmpty ||
    RideData.rides.last.tripTime != tripTime) {
  RideData.rides.add(
    RideHistory(
      pickup: "Current Location",
      destination: "Destination",
      fare: fare,
      distance: distance,
      tripTime: tripTime,
      date: DateTime.now().toString().substring(0, 16),
    ),
  );
}

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Completed"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 120,
            ),

            const SizedBox(height: 20),

            const Text(
              "Trip Completed",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.payments),
                title: const Text("Fare"),
                trailing: Text("NPR ${fare.toStringAsFixed(0)}"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: const Text("Distance"),
                trailing: Text("${distance.toStringAsFixed(2)} km"),
              ),
            ),

            Card(
  child: ListTile(
    leading: const Icon(Icons.local_taxi),
    title: const Text("Ride Type"),
    trailing: Text(rideType),
  ),
),

            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("Trip Time"),
                trailing: Text(tripTime),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Rate Driver",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                  fare: fare,
                  distance: distance,
                  rideType: rideType,
                  pickup: "Current Location",
                  destination: "Destination",
                  ),
                ),
              );
              },
            child: const Text("Continue to Payment"),
            ),
            ),
          ],
        ),
      ),
    );
  }
}