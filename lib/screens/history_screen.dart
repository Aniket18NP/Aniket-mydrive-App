import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/ride_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride History"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RideModel>>(
        stream: RideService().getUserRides(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No rides yet",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final rides = snapshot.data!;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_taxi),
                  ),

                  title: Text(
                    "${ride.pickup} → ${ride.destination}",
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ride: ${ride.rideType}",
                      ),

                      Text(
                        "Fare: NPR ${ride.fare.toStringAsFixed(0)}",
                      ),

                      Text(
                        "Distance: ${ride.distance.toStringAsFixed(2)} km",
                      ),

                      Text(
                        "Payment: ${ride.paymentMethod}",
                      ),

                      Text(
                        "Status: ${ride.status}",
                      ),

                      Text(
                        ride.createdAt.toString(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}