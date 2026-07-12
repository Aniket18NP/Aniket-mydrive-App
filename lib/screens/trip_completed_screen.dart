import 'package:flutter/material.dart';

import '../data/ride_data.dart';
import '../models/ride_history.dart';
import '../services/ride_request_service.dart';

import 'payment_screen.dart';

class TripCompletedScreen extends StatefulWidget {
  final String rideId;
  final double fare;
  final double distance;
  final String tripTime;
  final String rideType;
  final String pickup;
  final String destination;

  const TripCompletedScreen({
    super.key,
    required this.rideId,
    required this.fare,
    required this.distance,
    required this.tripTime,
    required this.rideType,
    required this.pickup,
    required this.destination,
  });

  @override
  State<TripCompletedScreen> createState() =>
      _TripCompletedScreenState();
}

class _TripCompletedScreenState
    extends State<TripCompletedScreen> {
  final RideRequestService _rideRequestService =
      RideRequestService();

  int selectedRating = 0;

  bool isSavingRating = false;

  // =========================================================
  // INITIALIZE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _addToLocalHistory();
  }

  // =========================================================
  // ADD TO LOCAL HISTORY
  // =========================================================

  void _addToLocalHistory() {
    if (RideData.rides.isEmpty ||
        RideData.rides.last.tripTime != widget.tripTime) {
      RideData.rides.add(
        RideHistory(
          pickup: widget.pickup,
          destination: widget.destination,
          fare: widget.fare,
          distance: widget.distance,
          tripTime: widget.tripTime,
          date: DateTime.now()
              .toString()
              .substring(0, 16),
        ),
      );
    }
  }

  // =========================================================
  // SELECT RATING
  // =========================================================

  void _selectRating(int rating) {
    setState(() {
      selectedRating = rating;
    });
  }

  // =========================================================
  // CONTINUE TO PAYMENT
  // =========================================================

  Future<void> _continueToPayment() async {
    if (isSavingRating) return;

    // Require the passenger to select a rating.
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a rating for your driver.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    setState(() {
      isSavingRating = true;
    });

    try {
      debugPrint('====================================');
      debugPrint('SAVING DRIVER RATING');
      debugPrint('Ride ID: ${widget.rideId}');
      debugPrint('Rating: $selectedRating');
      debugPrint('====================================');

      // Update the SAME existing ride document.
      await _rideRequestService.rateDriver(
        rideId: widget.rideId,
        rating: selectedRating,
      );

      debugPrint(
        'Driver rating saved successfully.',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            rideId: widget.rideId,
            fare: widget.fare,
            distance: widget.distance,
            rideType: widget.rideType,
            pickup: widget.pickup,
            destination: widget.destination,
          ),
        ),
      );

      // Reset loading state in case passenger comes back.
      if (mounted) {
        setState(() {
          isSavingRating = false;
        });
      }
    } catch (e) {
      debugPrint(
        'ERROR SAVING DRIVER RATING: $e',
      );

      if (!mounted) return;

      setState(() {
        isSavingRating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save rating: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // BUILD STAR
  // =========================================================

  Widget _buildStar(int starNumber) {
    final bool isSelected =
        starNumber <= selectedRating;

    return IconButton(
      onPressed: isSavingRating
          ? null
          : () {
              _selectRating(starNumber);
            },
      iconSize: 43,
      tooltip: '$starNumber star rating',
      icon: Icon(
        isSelected
            ? Icons.star
            : Icons.star_border,
        color: isSelected
            ? Colors.amber
            : Colors.grey.shade400,
      ),
    );
  }

  // =========================================================
  // RATING TEXT
  // =========================================================

  String get ratingText {
    switch (selectedRating) {
      case 1:
        return 'Poor';

      case 2:
        return 'Fair';

      case 3:
        return 'Good';

      case 4:
        return 'Very Good';

      case 5:
        return 'Excellent!';

      default:
        return 'Tap a star to rate your driver';
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'Trip Completed',
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
            // COMPLETED HEADER
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 78,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Trip Completed!',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'You have successfully reached your destination.',
                    textAlign: TextAlign.center,
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
            // TRIP SUMMARY
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
                    'Trip Summary',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildDetailRow(
                    icon: Icons.my_location,
                    title: 'Pickup',
                    value: widget.pickup,
                    color: Colors.green,
                  ),

                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'Destination',
                    value: widget.destination,
                    color: Colors.red,
                  ),

                  _buildDetailRow(
                    icon: Icons.local_taxi,
                    title: 'Ride Type',
                    value: widget.rideType,
                    color: Colors.blue,
                  ),

                  _buildDetailRow(
                    icon: Icons.route,
                    title: 'Distance',
                    value:
                        '${widget.distance.toStringAsFixed(2)} km',
                    color: Colors.purple,
                  ),

                  _buildDetailRow(
                    icon: Icons.timer_outlined,
                    title: 'Trip Time',
                    value: widget.tripTime,
                    color: Colors.orange,
                  ),

                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    title: 'Fare',
                    value:
                        'NPR ${widget.fare.toStringAsFixed(0)}',
                    color: Colors.green,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // DRIVER RATING
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate Your Driver',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'How was your experience with the driver?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => _buildStar(index + 1),
                    ),
                  ),

                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 200),
                    child: Text(
                      ratingText,
                      key: ValueKey(selectedRating),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selectedRating > 0
                            ? Colors.amber.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =================================================
            // CONTINUE TO PAYMENT BUTTON
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),

                onPressed: isSavingRating
                    ? null
                    : _continueToPayment,

                icon: isSavingRating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.payment,
                      ),

                label: Text(
                  isSavingRating
                      ? 'Saving Rating...'
                      : 'Continue to Payment',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!isLast) ...[
          const SizedBox(height: 13),
          Divider(
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 13),
        ],
      ],
    );
  }
}