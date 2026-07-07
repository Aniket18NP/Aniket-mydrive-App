import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'driver_found_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final double distanceKm;
  final String eta;
  final List<LatLng> routePoints;

  // NEW
  final String rideType;
  final double fare;

  const SearchingDriverScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    required this.eta,
    required this.routePoints,

    // NEW
    required this.rideType,
    required this.fare,
  });

  @override
  State<SearchingDriverScreen> createState() =>
      _SearchingDriverScreenState();
}

class _SearchingDriverScreenState
    extends State<SearchingDriverScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverFoundScreen(
              pickup: widget.pickup,
              destination: widget.destination,
              distanceKm: widget.distanceKm,
              eta: widget.eta,
              routePoints: widget.routePoints,

              // NEW
              rideType: widget.rideType,
              fare: widget.fare,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Searching Driver"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Searching for nearby drivers...",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                "Please wait while we find the best driver for you.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}