import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'live_trip_screen.dart';
import 'chat_screen.dart';
import '../services/ride_request_service.dart';

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
  State<DriverFoundScreen> createState() =>
      _DriverFoundScreenState();
}

class _DriverFoundScreenState extends State<DriverFoundScreen> {
  // =========================================================
  // FIRESTORE
  // =========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // RIDE LISTENER
  // =========================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _rideSubscription;

  // =========================================================
  // DRIVER DATA
  // =========================================================

  String driverId = '';

  String driverName = 'Loading driver...';

  String driverPhone = '';

  String vehicleType = 'Vehicle';

  String vehicleNumber = '';

  double driverRating = 0.0;

  int totalRatings = 0;

  // =========================================================
  // SCREEN STATES
  // =========================================================

  bool driverArrived = false;

  bool isLoadingDriver = true;

  bool arrivalMessageShown = false;

// Prevents LiveTripScreen from opening multiple times
bool tripScreenOpened = false;

String? driverLoadError;

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _listenToRide();
  }

  // =========================================================
  // LISTEN TO CURRENT RIDE
  // =========================================================

  void _listenToRide() {
    _rideSubscription = _firestore
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists) {
          debugPrint(
            'Ride document not found: ${widget.rideId}',
          );

          return;
        }

        final data = snapshot.data();

        if (data == null) return;

        final String status =
            data['status']?.toString() ?? '';

        final String newDriverId =
            data['driverId']?.toString().trim() ?? '';

        debugPrint('================================');
        debugPrint('RIDE UPDATE');
        debugPrint('Ride ID: ${widget.rideId}');
        debugPrint('Status: $status');
        debugPrint('Driver ID: $newDriverId');
        debugPrint('================================');

        // Load driver only when driver ID is available.
        if (newDriverId.isNotEmpty &&
            newDriverId != driverId) {
          driverId = newDriverId;

          await _loadDriverData(newDriverId);
        }

        // Handle driver arrival.
        if (status == 'Arrived') {
          if (!mounted) return;

          if (!driverArrived) {
            setState(() {
              driverArrived = true;
            });
          }

          if (!arrivalMessageShown) {
            arrivalMessageShown = true;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🎉 Your driver has arrived!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

      // Handle trip start from Driver App.
if (status == 'In Progress' && !tripScreenOpened) {
  tripScreenOpened = true;

  debugPrint('================================');
  debugPrint('🚗 TRIP START DETECTED');
  debugPrint('Ride ID: ${widget.rideId}');
  debugPrint('Opening LiveTripScreen...');
  debugPrint('================================');

  if (!mounted) return;

  // Cancel listener before navigating to prevent
  // duplicate navigation from repeated snapshots.
  await _rideSubscription?.cancel();

  if (!mounted) return;

  Navigator.pushReplacement(
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

      },
      onError: (error) {
        debugPrint(
          'ERROR LISTENING TO RIDE: $error',
        );
      },
    );
  }

  // =========================================================
  // LOAD REAL DRIVER DATA WITH AUTOMATIC RETRY
  // =========================================================

  Future<void> _loadDriverData(
    String currentDriverId,
  ) async {
    final String cleanDriverId =
        currentDriverId.trim();

    if (cleanDriverId.isEmpty) {
      debugPrint('❌ Driver ID is empty');

      if (!mounted) return;

      setState(() {
        isLoadingDriver = false;
        driverLoadError = 'Driver ID is unavailable.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoadingDriver = true;
        driverLoadError = null;
      });
    }

    debugPrint('================================');
    debugPrint('STARTING DRIVER LOAD');
    debugPrint(
      'Original driver ID: "$currentDriverId"',
    );
    debugPrint(
      'Clean driver ID: "$cleanDriverId"',
    );
    debugPrint(
      'ID length: ${cleanDriverId.length}',
    );
    debugPrint(
      'Firebase project: '
      '${_firestore.app.options.projectId}',
    );
    debugPrint('================================');

    // Try loading driver data up to 3 times.
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('================================');
        debugPrint(
          'DRIVER LOAD ATTEMPT: $attempt OF 3',
        );
        debugPrint(
          'Driver ID: $cleanDriverId',
        );
        debugPrint('================================');

        final driverDocument = await _firestore
            .collection('drivers')
            .doc(cleanDriverId)
            .get(
              const GetOptions(
                source: Source.server,
              ),
            );

        debugPrint('================================');
        debugPrint('DRIVER DOCUMENT RESULT');
        debugPrint(
          'Exists: ${driverDocument.exists}',
        );
        debugPrint(
          'Document ID: ${driverDocument.id}',
        );
        debugPrint(
          'Data: ${driverDocument.data()}',
        );
        debugPrint('================================');

        // Driver document genuinely does not exist.
        if (!driverDocument.exists) {
          debugPrint(
            '❌ DRIVER DOCUMENT DOES NOT EXIST',
          );

          if (!mounted) return;

          setState(() {
            driverName = 'Driver';
            driverPhone = '';
            vehicleType = 'Vehicle';
            vehicleNumber = '';
            driverRating = 0.0;
            totalRatings = 0;
            isLoadingDriver = false;
            driverLoadError =
                'Driver profile was not found.';
          });

          return;
        }

        final Map<String, dynamic>? driverData =
            driverDocument.data();

        if (driverData == null) {
          debugPrint(
            '❌ DRIVER DOCUMENT DATA IS NULL',
          );

          if (!mounted) return;

          setState(() {
            driverName = 'Driver';
            driverPhone = '';
            vehicleType = 'Vehicle';
            vehicleNumber = '';
            driverRating = 0.0;
            totalRatings = 0;
            isLoadingDriver = false;
            driverLoadError =
                'Driver information is unavailable.';
          });

          return;
        }

        debugPrint(
          'Driver name from Firestore: '
          '${driverData['name']}',
        );

        debugPrint(
          'Driver phone from Firestore: '
          '${driverData['phone']}',
        );

        debugPrint(
          'Vehicle type from Firestore: '
          '${driverData['vehicleType']}',
        );

        debugPrint(
          'Vehicle number from Firestore: '
          '${driverData['vehicleNumber']}',
        );

        debugPrint(
          'Profile rating from Firestore: '
          '${driverData['rating']}',
        );

        final dynamic ratingValue =
    driverData['rating'];

final dynamic ratingCountValue =
    driverData['ratingCount'];

final double realDriverRating =
    ratingValue is num
        ? ratingValue.toDouble().clamp(0.0, 5.0)
        : 5.0;

final int realRatingCount =
    ratingCountValue is num
        ? ratingCountValue.toInt()
        : 0;

        if (!mounted) return;

        setState(() {
          driverName =
              driverData['name']?.toString().trim().isNotEmpty ==
                      true
                  ? driverData['name'].toString().trim()
                  : 'Driver';

          driverPhone =
              driverData['phone']?.toString().trim() ?? '';

          vehicleType =
              driverData['vehicleType']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? driverData['vehicleType']
                      .toString()
                      .trim()
                  : 'Vehicle';

          vehicleNumber =
              driverData['vehicleNumber']
                      ?.toString()
                      .trim() ??
                  '';

         driverRating = realDriverRating;

          totalRatings = realRatingCount;
          isLoadingDriver = false;

          driverLoadError = null;
        });

        debugPrint('================================');
        debugPrint(
          '✅ DRIVER LOADED SUCCESSFULLY',
        );
        debugPrint('Name: $driverName');
        debugPrint('Phone: $driverPhone');
        debugPrint(
          'Vehicle type: $vehicleType',
        );
        debugPrint(
          'Vehicle number: $vehicleNumber',
        );
        debugPrint('Rating: $driverRating');
        debugPrint(
          'Total ratings: $totalRatings',
        );
        debugPrint('================================');

        // Driver successfully loaded.
        return;
      } catch (e, stackTrace) {
        debugPrint('================================');
        debugPrint(
          '❌ DRIVER LOAD ATTEMPT $attempt FAILED',
        );
        debugPrint('Error: $e');
        debugPrint(
          'Stack trace: $stackTrace',
        );
        debugPrint('================================');

        // Retry if there are attempts remaining.
        if (attempt < 3) {
          final int waitSeconds = attempt * 2;

          debugPrint(
            '⏳ Retrying in $waitSeconds seconds...',
          );

          await Future.delayed(
            Duration(seconds: waitSeconds),
          );

          if (!mounted) return;
        } else {
          debugPrint('================================');
          debugPrint(
            '❌ ALL 3 DRIVER LOAD ATTEMPTS FAILED',
          );
          debugPrint('================================');

          if (!mounted) return;

          setState(() {
            driverName = 'Driver';
            driverPhone = '';
            vehicleType = 'Vehicle';
            vehicleNumber = '';
            driverRating = 0.0;
            totalRatings = 0;
            isLoadingDriver = false;
            driverLoadError =
                'Unable to load driver information. '
                'Please check your internet connection.';
          });
        }
      }
    }
  }

  // =========================================================
  // CALCULATE REAL DRIVER RATING
  // =========================================================

  Future<_DriverRatingResult> _calculateDriverRating(
    String currentDriverId,
    Map<String, dynamic> driverData,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where(
            'driverId',
            isEqualTo: currentDriverId,
          )
          .get(
            const GetOptions(
              source: Source.server,
            ),
          );

      double total = 0.0;

      int count = 0;

      for (final document in snapshot.docs) {
        final data = document.data();

        final dynamic ratingValue =
            data['driverRating'];

        if (ratingValue is num) {
          final double rating =
              ratingValue.toDouble();

          // Only accept valid 1–5 star ratings.
          if (rating >= 1 && rating <= 5) {
            total += rating;
            count++;
          }
        }
      }

      // No passenger ratings yet.
      if (count == 0) {
        final dynamic defaultRating =
            driverData['rating'];

        if (defaultRating is num) {
          return _DriverRatingResult(
            average: defaultRating
                .toDouble()
                .clamp(0.0, 5.0),
            count: 0,
          );
        }

        return const _DriverRatingResult(
          average: 5.0,
          count: 0,
        );
      }

      return _DriverRatingResult(
        average: total / count,
        count: count,
      );
    } catch (e) {
      debugPrint(
        'ERROR CALCULATING DRIVER RATING: $e',
      );

      // If rating query fails, use the driver's
      // profile rating instead.
      final dynamic defaultRating =
          driverData['rating'];

      if (defaultRating is num) {
        return _DriverRatingResult(
          average:
              defaultRating.toDouble().clamp(0.0, 5.0),
          count: 0,
        );
      }

      return const _DriverRatingResult(
        average: 5.0,
        count: 0,
      );
    }
  }

  // =========================================================
  // RETRY DRIVER LOAD MANUALLY
  // =========================================================

  Future<void> _retryDriverLoad() async {
    if (driverId.isEmpty) {
      return;
    }

    await _loadDriverData(driverId);
  }

  // =========================================================
  // START RIDE
  // =========================================================

  void _startRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTripScreen(
          rideId: widget.rideId,
          pickup: widget.pickup,
          destination: widget.destination,
          pickupAddress: widget.pickupAddress,
          destinationAddress:
              widget.destinationAddress,
          distanceKm: widget.distanceKm,
          eta: widget.eta,
          routePoints: widget.routePoints,
          rideType: widget.rideType,
          fare: widget.fare,
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

Future<void> _callDriver() async {
  if (driverPhone.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver phone number is unavailable.'),
      ),
    );

    return;
  }

  final String cleanPhone = driverPhone.replaceAll(
    RegExp(r'[^\d+]'),
    '',
  );

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: cleanPhone,
  );

  try {
    final bool launched = await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the phone dialer.'),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error opening phone dialer: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to call the driver.'),
      ),
    );
  }
}

Future<void> _cancelRide() async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text(
          'Are you sure you want to cancel this ride?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Yes, Cancel Ride',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  try {
    await RideRequestService().cancelRideByPassenger(
      widget.rideId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ride cancelled successfully.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to cancel ride: $e',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    _rideSubscription?.cancel();

    super.dispose();
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
          'Driver Found',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoadingDriver
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),

                  SizedBox(height: 16),

                  Text(
                    'Loading driver information...',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  // ===========================================
                  // NETWORK / DRIVER LOAD ERROR
                  // ===========================================

                  if (driverLoadError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.orange,
                            size: 32,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            driverLoadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextButton.icon(
                            onPressed:
                                _retryDriverLoad,
                            icon: const Icon(
                              Icons.refresh,
                            ),
                            label: const Text(
                              'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],

                  // ===========================================
                  // DRIVER PROFILE
                  // ===========================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor:
                              Colors.blue.shade50,
                          child: const Icon(
                            Icons.person,
                            size: 62,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          driverName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 23,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              driverRating
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            if (totalRatings > 0) ...[
                              const SizedBox(width: 5),

                              Text(
                                '($totalRatings '
                                '${totalRatings == 1 ? 'rating' : 'ratings'})',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===========================================
                  // VEHICLE INFORMATION
                  // ===========================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.blue,
                            size: 32,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicleType,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                vehicleNumber.isEmpty
                                    ? 'Vehicle number unavailable'
                                    : vehicleNumber,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),

                            Text(
                              driverRating
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===========================================
                  // ROUTE INFORMATION
                  // ===========================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.my_location,
                          iconColor: Colors.green,
                          title: 'Pickup',
                          value: widget.pickupAddress,
                        ),

                        const Divider(height: 30),

                        _buildInfoRow(
                          icon: Icons.location_on,
                          iconColor: Colors.red,
                          title: 'Destination',
                          value:
                              widget.destinationAddress,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===========================================
                  // DRIVER STATUS
                  // ===========================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: driverArrived
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              driverArrived
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                          child: Icon(
                            driverArrived
                                ? Icons.check_circle
                                : Icons.location_on,
                            color: driverArrived
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverArrived
                                    ? 'Driver has arrived!'
                                    : 'Driver is on the way',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                driverArrived
                                    ? 'Your driver is waiting at the pickup point.'
                                    : 'ETA: ${widget.eta}',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===========================================
                  // RIDE TYPE AND FARE
                  // ===========================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_taxi,
                          color: Colors.blue,
                          size: 30,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            widget.rideType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          'NPR ${widget.fare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===========================================
                  // START RIDE
                  // ===========================================

                  SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: driverArrived
          ? Colors.orange
          : Colors.grey,
      foregroundColor: Colors.white,
      disabledBackgroundColor: driverArrived
          ? Colors.orange
          : Colors.grey.shade400,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    icon: Icon(
      driverArrived
          ? Icons.hourglass_top
          : Icons.directions_car,
    ),
    label: Text(
      driverArrived
          ? 'Waiting for Driver to Start Trip'
          : 'Driver is on the way',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    onPressed: null,
  ),
),

                  const SizedBox(height: 10),

                  // ===========================================
                  // CALL DRIVER
                  // ===========================================

                  SizedBox(
  width: double.infinity,
  height: 52,
  child: OutlinedButton.icon(
    icon: const Icon(Icons.call),
    label: const Text('Call Driver'),
    onPressed: driverPhone.isEmpty
        ? null
        : _callDriver,
  ),
),

                  const SizedBox(height: 10),

                  // ===========================================
                  // CHAT
                  // ===========================================

                  SizedBox(
  width: double.infinity,
  height: 52,
  child: OutlinedButton.icon(
    icon: const Icon(Icons.chat),
    label: const Text('Chat'),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            rideId: widget.rideId,
            driverName: driverName,
          ),
        ),
      );
    },
  ),
),

                  const SizedBox(height: 10),

                  // ===========================================
                  // CANCEL RIDE
                  // ===========================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _cancelRide,
                      child: const Text(
                        'Cancel Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
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
  // INFORMATION ROW
  // =========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 28,
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
    );
  }
}

// ===========================================================
// DRIVER RATING RESULT
// ===========================================================

class _DriverRatingResult {
  final double average;
  final int count;

  const _DriverRatingResult({
    required this.average,
    required this.count,
  });
}