class RideModel {
  final String rideId;
  final String passengerId;
  final String pickup;
  final String destination;
  final double distance;
  final double fare;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String rideType;

  RideModel({
  required this.rideId,
  required this.passengerId,
  required this.pickup,
  required this.destination,
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
      "pickup": pickup,
      "destination": destination,
      "rideType": rideType,
      "distance": distance,
      "fare": fare,
      "paymentMethod": paymentMethod,
      "status": status,
      "createdAt": createdAt,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      rideId: map["rideId"] ?? "",
      passengerId: map["passengerId"] ?? "",
      pickup: map["pickup"] ?? "",
      destination: map["destination"] ?? "",
      rideType: map["rideType"] ?? "",
      distance: (map["distance"] ?? 0).toDouble(),
      fare: (map["fare"] ?? 0).toDouble(),
      paymentMethod: map["paymentMethod"] ?? "",
      status: map["status"] ?? "",
      createdAt: (map["createdAt"] as dynamic).toDate(),
    );
  }
}