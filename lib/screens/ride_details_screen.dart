import 'package:flutter/material.dart';

import '../models/ride_model.dart';

class RideDetailsScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  // =========================================================
  // FORMAT DATE AND TIME
  // Example: 13 Jul 2026 • 9:30 AM
  // =========================================================

  String formatDateTime(DateTime date) {
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

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        months[date.month - 1];

    final int year = date.year;

    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year • '
        '$hour:$minute $period';
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'in progress':
        return Colors.purple;

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
  // RIDE ICON
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
  // DETAIL ROW
  // =========================================================

  Widget detailRow({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = Colors.blue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
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
    final Color statusColor =
        getStatusColor(ride.status);

    final bool isPaid =
        ride.paymentStatus.toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'Ride Details',
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
            // =================================================
            // STATUS CARD
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor:
                        statusColor.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      ride.status.toLowerCase() ==
                              'completed'
                          ? Icons.check_circle
                          : getRideIcon(
                              ride.rideType,
                            ),
                      color: statusColor,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    ride.status,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    formatDateTime(
                      ride.createdAt,
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // ROUTE DETAILS
            // =================================================

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
                    'Route Details',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  detailRow(
                    icon: Icons.my_location,
                    title: 'Pickup',
                    value: ride.pickup,
                    iconColor: Colors.green,
                  ),

                  detailRow(
                    icon: Icons.location_on,
                    title: 'Destination',
                    value: ride.destination,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // TRIP INFORMATION
            // =================================================

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
                    'Trip Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  detailRow(
                    icon: getRideIcon(
                      ride.rideType,
                    ),
                    title: 'Ride Type',
                    value: ride.rideType,
                  ),

                  detailRow(
                    icon: Icons.route,
                    title: 'Distance',
                    value:
                        '${ride.distance.toStringAsFixed(2)} km',
                    iconColor: Colors.purple,
                  ),

                  detailRow(
                    icon: Icons.payments,
                    title: 'Fare',
                    value:
                        'NPR ${ride.fare.toStringAsFixed(0)}',
                    iconColor: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // PAYMENT AND RATING
            // =================================================

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
                    'Payment & Rating',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  detailRow(
                    icon: Icons.payment,
                    title: 'Payment Method',
                    value: ride.paymentMethod.isEmpty
                        ? 'Not selected'
                        : ride.paymentMethod,
                    iconColor: Colors.orange,
                  ),

                  detailRow(
                    icon: isPaid
                        ? Icons.check_circle
                        : Icons.pending,
                    title: 'Payment Status',
                    value: ride.paymentStatus.isEmpty
                        ? 'Pending'
                        : ride.paymentStatus,
                    iconColor: isPaid
                        ? Colors.green
                        : Colors.orange,
                  ),

                  detailRow(
                    icon: Icons.star,
                    title: 'Your Rating',
                    value: ride.driverRating > 0
                        ? '${ride.driverRating}/5 ⭐'
                        : 'Not rated',
                    iconColor: Colors.amber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // TRIP TIMELINE
            // =================================================

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
                    'Trip Timeline',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  detailRow(
                    icon: Icons.calendar_today,
                    title: 'Booked At',
                    value: formatDateTime(
                      ride.createdAt,
                    ),
                    iconColor: Colors.blue,
                  ),

                  detailRow(
                    icon: Icons.play_circle,
                    title: 'Trip Started At',
                    value: ride.tripStartedAt == null
                        ? 'Not available'
                        : formatDateTime(
                            ride.tripStartedAt!,
                          ),
                    iconColor: Colors.purple,
                  ),

                  detailRow(
                    icon: Icons.flag,
                    title: 'Completed At',
                    value: ride.completedAt == null
                        ? 'Not available'
                        : formatDateTime(
                            ride.completedAt!,
                          ),
                    iconColor: Colors.green,
                  ),

                  detailRow(
                    icon: Icons.receipt_long,
                    title: 'Paid At',
                    value: ride.paidAt == null
                        ? 'Not available'
                        : formatDateTime(
                            ride.paidAt!,
                          ),
                    iconColor: Colors.teal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // RIDE ID
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ride ID',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 5),

                  SelectableText(
                    ride.rideId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}