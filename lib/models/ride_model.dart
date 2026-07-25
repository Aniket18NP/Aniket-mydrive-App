import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String rideId;
  final String passengerId;
  final String driverId;

  final String pickup;
  final String destination;

  final double distance;
  final double fare;

  final String rideType;
  final String paymentMethod;
  final String paymentStatus;
  final String status;

  final int driverRating;

  final DateTime createdAt;
  final DateTime? tripStartedAt;
  final DateTime? completedAt;
  final DateTime? paidAt;

  final double driverLatitude;
final double driverLongitude;

final double passengerLatitude;
final double passengerLongitude;

final double destinationLatitude;
final double destinationLongitude;

final DateTime? acceptedAt;
final DateTime? arrivedAt;

  RideModel({
    required this.rideId,
    required this.passengerId,
    this.driverId = '',
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.fare,
    required this.rideType,
    this.paymentMethod = '',
    this.paymentStatus = '',
    required this.status,
    this.driverRating = 0,
    required this.createdAt,
    this.tripStartedAt,
    this.completedAt,
    this.paidAt,
    this.driverLatitude = 0,
this.driverLongitude = 0,

this.passengerLatitude = 0,
this.passengerLongitude = 0,

this.destinationLatitude = 0,
this.destinationLongitude = 0,

this.acceptedAt,
this.arrivedAt,
  });

  // =========================================================
  // CONVERT MODEL TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'passengerId': passengerId,
      'driverId': driverId,
      'pickup': pickup,
      'destination': destination,
      'distance': distance,
      'fare': fare,
      'rideType': rideType,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'driverRating': driverRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'tripStartedAt': tripStartedAt == null
          ? null
          : Timestamp.fromDate(tripStartedAt!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'paidAt': paidAt == null
          ? null
          : Timestamp.fromDate(paidAt!),

      'driverLatitude': driverLatitude,
'driverLongitude': driverLongitude,

'passengerLatitude': passengerLatitude,
'passengerLongitude': passengerLongitude,

'destinationLatitude': destinationLatitude,
'destinationLongitude': destinationLongitude,

'acceptedAt': acceptedAt == null
    ? null
    : Timestamp.fromDate(acceptedAt!),

'arrivedAt': arrivedAt == null
    ? null
    : Timestamp.fromDate(arrivedAt!),
    };
  }

  // =========================================================
  // CONVERT FIRESTORE MAP TO MODEL
  // =========================================================

  factory RideModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RideModel(
  rideId: map['rideId']?.toString() ?? '',
  passengerId: map['passengerId']?.toString() ?? '',
  driverId: map['driverId']?.toString() ?? '',
  pickup: map['pickup']?.toString() ?? '',
  destination: map['destination']?.toString() ?? '',
  distance: _toDouble(map['distance']),
  fare: _toDouble(map['fare']),
  rideType: map['rideType']?.toString() ?? '',
  paymentMethod: map['paymentMethod']?.toString() ?? '',
  paymentStatus: map['paymentStatus']?.toString() ?? '',
  status: map['status']?.toString() ?? '',
  driverRating: _toInt(map['driverRating']),
  createdAt:
      _toDateTime(map['createdAt']) ?? DateTime.now(),
  tripStartedAt:
      _toDateTime(map['tripStartedAt']),
  completedAt:
      _toDateTime(map['completedAt']),
  paidAt:
      _toDateTime(map['paidAt']),

  driverLatitude:
      _toDouble(map['driverLatitude']),
  driverLongitude:
      _toDouble(map['driverLongitude']),

  passengerLatitude:
      _toDouble(map['passengerLatitude']),
  passengerLongitude:
      _toDouble(map['passengerLongitude']),

  destinationLatitude:
      _toDouble(map['destinationLatitude']),
  destinationLongitude:
      _toDouble(map['destinationLongitude']),

  acceptedAt:
      _toDateTime(map['acceptedAt']),

  arrivedAt:
      _toDateTime(map['arrivedAt']),
);
      
      
    
  }

  // =========================================================
  // SAFE DOUBLE CONVERSION
  // =========================================================

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // =========================================================
  // SAFE INT CONVERSION
  // =========================================================

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // SAFE DATE CONVERSION
  // =========================================================

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}