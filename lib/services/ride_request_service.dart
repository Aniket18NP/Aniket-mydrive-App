import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_request_model.dart';

class RideRequestService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // CREATE RIDE REQUEST
  // =========================================================

  Future<void> createRideRequest(
    RideRequestModel ride,
  ) async {
    await _firestore
        .collection("rides")
        .doc(ride.rideId)
        .set(ride.toMap());
  }

  // =========================================================
  // LISTEN FOR SEARCHING RIDES
  // =========================================================

  Stream<List<RideRequestModel>> getSearchingRides() {
    return _firestore
        .collection("rides")
        .where(
          "status",
          isEqualTo: "Searching",
        )
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RideRequestModel.fromMap(
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  // =========================================================
  // ACCEPT RIDE
  // =========================================================

  Future<void> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "driverId": driverId,
      "status": "Accepted",
    });
  }

  // =========================================================
  // DRIVER ARRIVED
  // =========================================================

  Future<void> driverArrived(
    String rideId,
  ) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "status": "Arrived",
    });
  }

  // =========================================================
  // REJECT RIDE
  // =========================================================

  Future<void> rejectRide(
    String rideId,
  ) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "status": "Rejected",
    });
  }

  // =========================================================
  // COMPLETE RIDE
  // =========================================================

  Future<void> completeRide(
    String rideId,
  ) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "status": "Completed",
    });
  }

  // =========================================================
  // RATE DRIVER
  // Updates the SAME existing ride document.
  // Does NOT create a new document.
  // =========================================================

  Future<void> rateDriver({
    required String rideId,
    required int rating,
  }) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "driverRating": rating,
      "ratedAt": FieldValue.serverTimestamp(),
    });
  }
}