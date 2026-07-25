import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/ride_service.dart';

import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // =========================================================
  // LOGOUT CONFIRMATION
  // =========================================================

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE INFORMATION TILE
  // =========================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // =======================================================
    // USER NOT LOGGED IN
    // =======================================================

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your profile.',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
        ),
      );
    }

    final uid = currentUser.uid;

    return StreamBuilder<UserModel?>(
      stream: FirestoreService().getUserStream(uid),

      builder: (context, userSnapshot) {
        // ===================================================
        // USER LOADING
        // ===================================================

        if (userSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ===================================================
        // USER ERROR
        // ===================================================

        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Could not load profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${userSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ===================================================
        // USER NOT FOUND
        // ===================================================

        if (!userSnapshot.hasData ||
            userSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              centerTitle: true,
            ),
            body: const Center(
              child: Text(
                'Profile information not found.',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          );
        }

        final user = userSnapshot.data!;

        // ===================================================
        // RIDE STATISTICS
        // ===================================================

        return StreamBuilder<List<RideModel>>(
          stream: RideService().getAllUserRides(uid),

          builder: (context, rideSnapshot) {
            if (rideSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (rideSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('My Profile'),
                  centerTitle: true,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load ride statistics.\n\n'
                      '${rideSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final rides = rideSnapshot.data ?? [];

            // Only completed rides are used for statistics.
            final completedRides = rides.where(
              (ride) =>
                  ride.status.toLowerCase() == 'completed',
            ).toList();

            final totalTrips = completedRides.length;

            final totalSpent = completedRides.fold<double>(
              0,
              (sum, ride) => sum + ride.fare,
            );

            final totalDistance =
                completedRides.fold<double>(
              0,
              (sum, ride) => sum + ride.distance,
            );

            // =================================================
            // PROFILE SCREEN
            // =================================================

            return Scaffold(
              backgroundColor: Colors.grey.shade100,

              appBar: AppBar(
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),

              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    // =========================================
                    // PROFILE HEADER
                    // =========================================

                   Container(
  width: 110,
  height: 110,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.blue.shade100,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ClipOval(
    child: user.profileImage.isNotEmpty
        ? Image.network(
            user.profileImage,
            fit: BoxFit.cover,
            loadingBuilder: (
              context,
              child,
              progress,
            ) {
              if (progress == null) {
                return child;
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder:
                (_, __, ___) => const Icon(
              Icons.person,
              size: 60,
              color: Colors.blue,
            ),
          )
        : const Icon(
            Icons.person,
            size: 60,
            color: Colors.blue,
          ),
  ),
),

                    const SizedBox(height: 16),

                    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Flexible(
      child: Text(
        user.fullName.isEmpty
            ? 'MyDrive Passenger'
            : user.fullName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    const SizedBox(width: 8),
    const Icon(
      Icons.verified,
      color: Colors.green,
      size: 22,
    ),
  ],
),

const SizedBox(height: 6),

Text(
  user.email,
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 15,
    color: Colors.grey.shade600,
  ),
),

const SizedBox(height: 10),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  ),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(20),
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 18,
      ),
      SizedBox(width: 6),
      Text(
        "Verified Passenger",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),

const SizedBox(height: 18),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        ),
      );
    },
    icon: const Icon(Icons.edit),
    label: const Text("Edit Profile"),
  ),
),

const SizedBox(height: 16),

                    // =========================================
                    // STATISTICS
                    // =========================================

                    Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.local_taxi,
                          value: totalTrips.toString(),
                          label: 'Trips',
                          color: Colors.blue,
                        ),

                        const SizedBox(width: 10),

                        _buildStatCard(
                          icon: Icons.payments,
                          value:
                              'NPR ${totalSpent.toStringAsFixed(0)}',
                          label: 'Spent',
                          color: Colors.green,
                        ),

                        const SizedBox(width: 10),

                        _buildStatCard(
                          icon: Icons.route,
                          value:
                              '${totalDistance.toStringAsFixed(1)} km',
                          label: 'Distance',
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // =========================================
                    // PERSONAL INFORMATION
                    // =========================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildInfoTile(
                            icon: Icons.person_outline,
                            title: 'Full Name',
                            value: user.fullName,
                            color: Colors.blue,
                          ),

                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: user.email,
                            color: Colors.orange,
                          ),

                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            title: 'Phone',
                            value: user.phone,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================================
                    // RATING
                    // =========================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 15),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Passenger Rating',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  'Based on your completed rides',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Text(
                            '4.9 ⭐',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // LOGOUT BUTTON
                    // =========================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ),

                    const SizedBox(height: 30),
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