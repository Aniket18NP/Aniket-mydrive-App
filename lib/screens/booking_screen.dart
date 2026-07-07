import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String selectedRide = "Car";

  Widget rideTile(
    String title,
    String price,
    IconData icon,
    Color color,
  ) {
    bool selected = selectedRide == title;

    return Card(
      elevation: selected ? 6 : 2,
      color: selected ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 35,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(price),
        trailing: selected
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
              )
            : null,
        onTap: () {
          setState(() {
            selectedRide = title;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Your Ride"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Pickup Location",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                decoration: InputDecoration(
                  hintText: "Current Location",
                  prefixIcon: const Icon(Icons.my_location),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Drop Location",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                decoration: InputDecoration(
                  hintText: "Destination",
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Choose Ride",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              rideTile(
                "Car",
                "NPR 250",
                Icons.local_taxi,
                Colors.blue,
              ),

              rideTile(
                "Bike",
                "NPR 150",
                Icons.motorcycle,
                Colors.orange,
              ),

              rideTile(
                "Auto",
                "NPR 180",
                Icons.electric_rickshaw,
                Colors.green,
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Distance"),
                        Text("6.2 km"),
                      ],
                    ),

                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Estimated Time"),
                        Text("18 mins"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "$selectedRide booked successfully!",
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "CONFIRM BOOKING",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}