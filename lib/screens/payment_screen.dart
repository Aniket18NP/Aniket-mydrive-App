import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_model.dart';
import '../services/ride_service.dart';

class PaymentScreen extends StatefulWidget {
  final double fare;
  final double distance;
  final String rideType;
  final String pickup;
  final String destination;

  const PaymentScreen({
    super.key,
    required this.fare,
    required this.distance,
    required this.rideType,
    required this.pickup,
    required this.destination,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selected = "Cash";
  final RideService _rideService = RideService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              "Total Fare",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 10),

            Text(
              "NPR ${widget.fare.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 40),

            RadioListTile(
              value: "Cash",
              groupValue: selected,
              onChanged: (value) {
                setState(() {
                  selected = value.toString();
                });
              },
              title: const Text("Cash"),
            ),

            RadioListTile(
              value: "Card",
              groupValue: selected,
              onChanged: (value) {
                setState(() {
                  selected = value.toString();
                });
              },
              title: const Text("Credit / Debit Card"),
            ),

            RadioListTile(
              value: "Wallet",
              groupValue: selected,
              onChanged: (value) {
                setState(() {
                  selected = value.toString();
                });
              },
              title: const Text("Digital Wallet"),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Pay"),
                onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final ride = RideModel(
    rideId: FirebaseFirestore.instance.collection("rides").doc().id,
    passengerId: user.uid,
    pickup: widget.pickup,
    destination: widget.destination,
    distance: widget.distance,
    fare: widget.fare,
    rideType: widget.rideType,
    paymentMethod: selected,
    status: "Completed",
    createdAt: DateTime.now(),
  );

  await _rideService.createRide(ride);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("$selected payment successful!"),
    ),
  );

  Navigator.popUntil(
    context,
    (route) => route.isFirst,
  );
},
              ),
            ),
          ],
        ),
      ),
    );
  }
}