import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/ride_service.dart';

import 'ride_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // =========================================================
  // FORMAT DATE AND TIME
  // Example: 10 Jul 2026 • 3:02 PM
  // =========================================================

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year • $hour:$minute $period';
  }

  // =========================================================
  // GET STATUS COLOR
  // =========================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'accepted':
        return Colors.blue;

      case 'arrived':
        return Colors.orange;

      case 'searching':
        return Colors.amber.shade700;

      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // GET RIDE ICON
  // =========================================================

  IconData getRideIcon(String rideType) {
    switch (rideType.toLowerCase()) {
      case 'bike':
        return Icons.motorcycle;

      case 'suv':
        return Icons.airport_shuttle;

      case 'economy':
        return Icons.directions_car;

      case 'auto':
        return Icons.electric_rickshaw;

      default:
        return Icons.local_taxi;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // User not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ride History'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your ride history.',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // =====================================================
      // FIRESTORE RIDE HISTORY
      // =====================================================

      body: StreamBuilder<List<RideModel>>(
        stream: RideService().getUserRides(user.uid),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
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
                      'Could not load ride history',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // No rides
          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 90,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 20),

                    Text(
                      'No rides yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Your rides will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final rides = snapshot.data!;

          // =================================================
          // RIDE LIST
          // =================================================

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              24,
            ),
            itemCount: rides.length,

            itemBuilder: (context, index) {
              final ride = rides[index];

              final statusColor =
                  getStatusColor(ride.status);

              return InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideDetailsScreen(
          ride: ride,
        ),
      ),
    );
  },
  child: Card(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // =====================================
                      // TOP ROW
                      // =====================================

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Colors.blue.shade50,
                            child: Icon(
                              getRideIcon(ride.rideType),
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.rideType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  formatDate(
                                    ride.createdAt,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              ride.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 12),

                      // =====================================
                      // PICKUP
                      // =====================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 21,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  ride.pickup,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // =====================================
                      // DESTINATION
                      // =====================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 22,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  ride.destination,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 10),

                      // =====================================
                      // FARE, DISTANCE, PAYMENT
                      // =====================================

                      Row(
                        children: [
                          // Fare
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fare',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'NPR ${ride.fare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Distance
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Distance',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  '${ride.distance.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Payment
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Payment',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  ride.paymentMethod.isEmpty
                                      ? 'Not selected'
                                      : ride.paymentMethod,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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