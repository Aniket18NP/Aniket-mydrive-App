class RideRequestModel {
  final String rideId;
  final String passengerId;
  final String driverId;

  final String pickup;
  final String destination;

  final double pickupLat;
  final double pickupLng;

  final double destinationLat;
  final double destinationLng;

  final double distance;
  final double fare;

  final String rideType;

  final String paymentMethod;

  final String status;

  final DateTime createdAt;

  RideRequestModel({
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.pickup,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.distance,
    required this.fare,
    required this.rideType,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "rideId": rideId,
      "passengerId": passengerId,
      "driverId": driverId,
      "pickup": pickup,
      "destination": destination,
      "pickupLat": pickupLat,
      "pickupLng": pickupLng,
      "destinationLat": destinationLat,
      "destinationLng": destinationLng,
      "distance": distance,
      "fare": fare,
      "rideType": rideType,
      "paymentMethod": paymentMethod,
      "status": status,
      "createdAt": createdAt,
    };
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    return RideRequestModel(
      rideId: map["rideId"] ?? "",
      passengerId: map["passengerId"] ?? "",
      driverId: map["driverId"] ?? "",
      pickup: map["pickup"] ?? "",
      destination: map["destination"] ?? "",
      pickupLat: (map["pickupLat"] ?? 0).toDouble(),
      pickupLng: (map["pickupLng"] ?? 0).toDouble(),
      destinationLat: (map["destinationLat"] ?? 0).toDouble(),
      destinationLng: (map["destinationLng"] ?? 0).toDouble(),
      distance: (map["distance"] ?? 0).toDouble(),
      fare: (map["fare"] ?? 0).toDouble(),
      rideType: map["rideType"] ?? "",
      paymentMethod: map["paymentMethod"] ?? "",
      status: map["status"] ?? "",
      createdAt: map["createdAt"].toDate(),
    );
  }
}