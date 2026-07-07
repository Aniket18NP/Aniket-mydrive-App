import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_model.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new ride
  Future<void> createRide(RideModel ride) async {
    await _firestore
        .collection("rides")
        .doc(ride.rideId)
        .set(ride.toMap());
  }

  /// Get all rides for one passenger (Newest first)
  Stream<List<RideModel>> getUserRides(String passengerId) {
    return _firestore
        .collection("rides")
        .where("passengerId", isEqualTo: passengerId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get all rides for profile statistics
  Stream<List<RideModel>> getAllUserRides(String passengerId) {
    return _firestore
        .collection("rides")
        .where("passengerId", isEqualTo: passengerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update ride status
  Future<void> updateRideStatus(
    String rideId,
    String status,
  ) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .update({
      "status": status,
    });
  }

  /// Cancel ride
  Future<void> cancelRide(String rideId) async {
    await updateRideStatus(
      rideId,
      "Cancelled",
    );
  }

  /// Delete ride
  Future<void> deleteRide(String rideId) async {
    await _firestore
        .collection("rides")
        .doc(rideId)
        .delete();
  }
}