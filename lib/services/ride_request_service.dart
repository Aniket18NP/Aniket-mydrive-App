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
  // Only allow ratings from 1 to 5.
  if (rating < 1 || rating > 5) {
    throw Exception(
      "Rating must be between 1 and 5.",
    );
  }

  final DocumentReference<Map<String, dynamic>> rideRef =
      _firestore
          .collection("rides")
          .doc(rideId);

  await _firestore.runTransaction((transaction) async {
    // -------------------------------------------------------
    // 1. GET THE RIDE
    // -------------------------------------------------------

    final rideSnapshot =
        await transaction.get(rideRef);

    if (!rideSnapshot.exists) {
      throw Exception("Ride not found.");
    }

    final rideData = rideSnapshot.data();

    if (rideData == null) {
      throw Exception("Ride data is empty.");
    }

    final String driverId =
        rideData["driverId"]?.toString() ?? "";

    if (driverId.isEmpty) {
      throw Exception(
        "No driver is assigned to this ride.",
      );
    }

    // Prevent the same ride from affecting
    // the driver's average rating more than once.
    final bool alreadyRated =
        rideData["driverRating"] != null;

    if (alreadyRated) {
      throw Exception(
        "This ride has already been rated.",
      );
    }

    // -------------------------------------------------------
    // 2. GET THE DRIVER PROFILE
    // -------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        driverRef = _firestore
            .collection("drivers")
            .doc(driverId);

    final driverSnapshot =
        await transaction.get(driverRef);

    if (!driverSnapshot.exists) {
      throw Exception(
        "Driver profile not found.",
      );
    }

    final driverData = driverSnapshot.data() ?? {};

    final int currentRatingCount =
        (driverData["ratingCount"] as num?)
                ?.toInt() ??
            0;

    final int currentRatingTotal =
        (driverData["ratingTotal"] as num?)
                ?.toInt() ??
            0;

    // -------------------------------------------------------
    // 3. CALCULATE NEW AVERAGE
    // -------------------------------------------------------

    final int newRatingCount =
        currentRatingCount + 1;

    final int newRatingTotal =
        currentRatingTotal + rating;

    final double newAverageRating =
        newRatingTotal / newRatingCount;

    // -------------------------------------------------------
    // 4. UPDATE THE RIDE
    // -------------------------------------------------------

    transaction.update(
      rideRef,
      {
        "driverRating": rating,
        "ratedAt": FieldValue.serverTimestamp(),
      },
    );

    // -------------------------------------------------------
    // 5. UPDATE THE DRIVER PROFILE
    // -------------------------------------------------------

    transaction.update(
      driverRef,
      {
        "rating": newAverageRating,
        "ratingCount": newRatingCount,
        "ratingTotal": newRatingTotal,
      },
    );
  });
}

// =========================================================
// CANCEL RIDE BY PASSENGER
// =========================================================

// =========================================================
// CANCEL RIDE BY PASSENGER
// =========================================================

Future<void> cancelRideByPassenger({
  required String rideId,
  required String reason,
}) async {
  if (reason.trim().isEmpty) {
    throw Exception(
      "Please select a cancellation reason.",
    );
  }

  final rideRef = _firestore
      .collection("rides")
      .doc(rideId);

  await _firestore.runTransaction(
    (transaction) async {
      final rideSnapshot =
          await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw Exception("Ride not found.");
      }

      final data = rideSnapshot.data();

      if (data == null) {
        throw Exception(
          "Ride data is unavailable.",
        );
      }

      final String currentStatus =
          data["status"]?.toString() ?? "";

      final bool canCancel =
          currentStatus == "Searching" ||
          currentStatus == "Accepted" ||
          currentStatus == "Arrived";

      if (!canCancel) {
        throw Exception(
          "This ride can no longer be cancelled.",
        );
      }

      transaction.update(
        rideRef,
        {
          "status": "Cancelled",
          "cancelledBy": "Passenger",
          "cancellationReason": reason.trim(),
          "cancelledAt":
              FieldValue.serverTimestamp(),
        },
      );
      final String driverId =
    data["driverId"]?.toString() ?? "";

// If a driver already accepted this ride,
// update that driver's availability.
if (driverId.isNotEmpty) {
  final driverRef = _firestore
      .collection("drivers")
      .doc(driverId);

  final driverSnapshot =
      await transaction.get(driverRef);

  if (driverSnapshot.exists) {
    final driverData =
        driverSnapshot.data() ?? {};

    final bool driverIsOnline =
        driverData["isOnline"] == true;

    // Driver becomes available only
    // if the driver is still online.
    transaction.update(
      driverRef,
      {
        "isAvailable": driverIsOnline,
      },
    );
  }
}
    },
  );
}
}