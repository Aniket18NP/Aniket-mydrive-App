import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../screens/searching_driver_screen.dart';

class RideBottomSheet extends StatefulWidget {
  final double bikeFare;
  final double economyFare;
  final double suvFare;
  final String duration;
  final double distance;

  final LatLng pickup;
  final LatLng destination;

  final String pickupAddress;
  final String destinationAddress;

  final List<LatLng> routePoints;

  const RideBottomSheet({
    super.key,
    required this.bikeFare,
    required this.economyFare,
    required this.suvFare,
    required this.duration,
    required this.distance,
    required this.pickup,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.routePoints,
  });

  @override
  State<RideBottomSheet> createState() => _RideBottomSheetState();
}

class _RideBottomSheetState extends State<RideBottomSheet> {
  String selectedRide = "Economy";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Choose your Ride",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            "${widget.distance.toStringAsFixed(1)} km • ${widget.duration}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          rideTile(
            icon: Icons.directions_car,
            title: "Economy",
            fare: "NPR ${widget.economyFare.toStringAsFixed(0)}",
            eta: widget.duration,
          ),

          rideTile(
            icon: Icons.motorcycle,
            title: "Bike",
            fare: "NPR ${widget.bikeFare.toStringAsFixed(0)}",
            eta: widget.duration,
          ),

          rideTile(
            icon: Icons.airport_shuttle,
            title: "SUV",
            fare: "NPR ${widget.suvFare.toStringAsFixed(0)}",
            eta: widget.duration,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                double selectedFare;

                switch (selectedRide) {
                  case "Bike":
                    selectedFare = widget.bikeFare;
                    break;

                  case "SUV":
                    selectedFare = widget.suvFare;
                    break;

                  default:
                    selectedFare = widget.economyFare;
                }

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchingDriverScreen(
                      pickup: widget.pickup,
                      destination: widget.destination,

                      pickupAddress: widget.pickupAddress,
                      destinationAddress: widget.destinationAddress,

                      distanceKm: widget.distance,
                      eta: widget.duration,
                      routePoints: widget.routePoints,

                      // REQUIRED
                      rideType: selectedRide,
                      fare: selectedFare,
                    ),
                  ),
                );
              },
              child: Text("Confirm $selectedRide"),
            ),
          ),
        ],
      ),
    );
  }

  Widget rideTile({
    required IconData icon,
    required String title,
    required String fare,
    required String eta,
  }) {
    final bool isSelected = selectedRide == title;

    return Card(
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        onTap: () {
          setState(() {
            selectedRide = title;
          });
        },
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.black,
          size: 35,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(eta),
        trailing: Text(
          fare,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}