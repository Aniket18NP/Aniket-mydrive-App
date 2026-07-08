import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_request_model.dart';

class RideRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create Ride Request
  Future<void> createRideRequest(
    RideRequestModel ride,
  ) async {
    await _firestore
        .collection("rides")
        .doc(ride.rideId)
        .set(ride.toMap());
  }

  /// Listen for Searching Rides
  Stream<List<RideRequestModel>> getSearchingRides() {
    return _firestore
        .collection("rides")
        .where("status", isEqualTo: "Searching")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RideRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Accept Ride
  Future<void> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    await _firestore.collection("rides").doc(rideId).update({
      "driverId": driverId,
      "status": "Accepted",
    });
  }

  /// Reject Ride
  Future<void> rejectRide(
    String rideId,
  ) async {
    await _firestore.collection("rides").doc(rideId).update({
      "status": "Rejected",
    });
  }

  /// Complete Ride
  Future<void> completeRide(
    String rideId,
  ) async {
    await _firestore.collection("rides").doc(rideId).update({
      "status": "Completed",
    });
  }
}