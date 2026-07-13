import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final double fare;
  final double distance;
  final String rideType;
  final String pickup;
  final String destination;

  const PaymentScreen({
    super.key,
    required this.rideId,
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
  bool isProcessing = false;

  Future<void> processPayment() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      print("Processing payment...");
      print("Ride ID: ${widget.rideId}");
      print("Payment Method: $selected");

      await FirebaseFirestore.instance
          .collection("rides")
          .doc(widget.rideId)
          .update({
  "paymentMethod": selected,
  "paymentStatus": "Paid",
  "paidAt": FieldValue.serverTimestamp(),
});

      print("Payment updated successfully!");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$selected payment successful!",
          ),
        ),
      );

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      print("Payment Error: $e");

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Payment failed: $e",
          ),
        ),
      );
    }
  }

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

            RadioListTile<String>(
              value: "Cash",
              groupValue: selected,
              onChanged: isProcessing
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        selected = value;
                      });
                    },
              title: const Text("Cash"),
            ),

            RadioListTile<String>(
              value: "Card",
              groupValue: selected,
              onChanged: isProcessing
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        selected = value;
                      });
                    },
              title: const Text(
                "Credit / Debit Card",
              ),
            ),

            RadioListTile<String>(
              value: "Wallet",
              groupValue: selected,
              onChanged: isProcessing
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        selected = value;
                      });
                    },
              title: const Text("Digital Wallet"),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    isProcessing ? null : processPayment,
                child: isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Pay NPR ${widget.fare.toStringAsFixed(0)}",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}