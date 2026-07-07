import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/ride_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<UserModel?>(
      stream: FirestoreService().getUserStream(uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = userSnapshot.data!;

        return StreamBuilder<List<RideModel>>(
          stream: RideService().getAllUserRides(uid),
          builder: (context, rideSnapshot) {
            if (!rideSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final rides = rideSnapshot.data!;

            final totalTrips = rides.length;

            final totalSpent = rides.fold<double>(
              0,
              (sum, ride) => sum + ride.fare,
            );

            final totalDistance = rides.fold<double>(
              0,
              (sum, ride) => sum + ride.distance,
            );

            return Scaffold(
              appBar: AppBar(
                title: const Text("My Profile"),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(
                        Icons.person,
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text("Phone"),
                        subtitle: Text(user.phone),
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text("Completed Trips"),
                        trailing: Text(totalTrips.toString()),
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments),
                        title: const Text("Total Spent"),
                        trailing: Text(
                          "NPR ${totalSpent.toStringAsFixed(0)}",
                        ),
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.route),
                        title: const Text("Total Distance"),
                        trailing: Text(
                          "${totalDistance.toStringAsFixed(1)} km",
                        ),
                      ),
                    ),

                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.star),
                        title: Text("Rating"),
                        trailing: Text("4.9 ⭐"),
                      ),
                    ),

                    SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.edit),
    label: const Text("Edit Profile"),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        ),
      );
    },
  ),
),

const SizedBox(height: 15),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          if (!context.mounted) return;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}