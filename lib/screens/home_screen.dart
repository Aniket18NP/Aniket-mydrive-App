import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'map_screen.dart';

import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  List<Placemark> placemarks =
      await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  if (placemarks.isNotEmpty) {
    Placemark place = placemarks.first;

    _pickupController.text =
        "${place.street}, ${place.locality}";
  }
}

  final TextEditingController _pickupController =
    TextEditingController();

final TextEditingController _destinationController =
    TextEditingController();

@override
void initState() {
  super.initState();

  _getCurrentLocation();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "MyDrive",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Good Morning 👋",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Where would you like to go?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
  controller: _pickupController,
  decoration: InputDecoration(
    hintText: "Pickup Location",
    prefixIcon: const Icon(
      Icons.my_location,
      color: Colors.green,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),
),

            TextField(
  controller: _destinationController,
  decoration: InputDecoration(
    hintText: "Drop Location",
    prefixIcon: const Icon(
      Icons.location_on,
      color: Colors.red,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),
),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),

                label: const Text(
                  "Find Ride",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),

                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MapScreen(),
    ),
  );
},
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              "Choose Ride",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                rideCard(Icons.local_taxi, "Car", Colors.blue),
                rideCard(Icons.motorcycle, "Bike", Colors.orange),
                rideCard(Icons.electric_rickshaw, "Auto", Colors.green),
              ],
            ),

            const SizedBox(height: 35),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [

                  Icon(
                    Icons.discount,
                    color: Colors.white,
                    size: 45,
                  ),

                  SizedBox(height: 10),

                  Text(
                    "20% OFF",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Use Code: MYDRIVE20",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

     bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: Colors.blue,
  onTap: (index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
        ),
      );
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: "History",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profile",
    ),
  ],
),
    );
  }

  static Widget rideCard(
    IconData icon,
    String title,
    Color color,
  ) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            size: 45,
            color: color,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}