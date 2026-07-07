import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/route_service.dart';
import '../services/fare_service.dart';

import 'history_screen.dart';


import '../widgets/ride_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  final LocationService locationService = LocationService();
  final PlacesService placesService = PlacesService();
  final RouteService routeService = RouteService();
  final FareService fareService = FareService();

  final TextEditingController searchController =
      TextEditingController();

  final PolylinePoints polylinePoints =
      PolylinePoints();

  Position? currentPosition;

 LatLng? passengerPosition;

LatLng? selectedDestination = const LatLng(
  27.7172,
  85.3240,
);

LatLng? driverPosition;

  List<dynamic> suggestions = [];

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};


  List<LatLng> routePoints = [];

  BitmapDescriptor? carIcon;

  Timer? driverTimer;

  double bikeFare = 0;
  double economyFare = 0;
  double suvFare = 0;

  double distanceKm = 0;

  String duration = "";

  String rideStatus = "Searching Driver...";

  final CameraPosition initialPosition =
      const CameraPosition(
    target: LatLng(27.7172, 85.3240),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();

    loadCarIcon();
    getCurrentLocation();
  }

    Future<void> loadCarIcon() async {
    carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(60, 60)),
      "assets/images/car.png",
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> getCurrentLocation() async {
    currentPosition = await locationService.getCurrentLocation();

    if (currentPosition == null) return;

    passengerPosition = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    markers.add(
      Marker(
        markerId: const MarkerId("passenger"),
        position: passengerPosition!,
        infoWindow: const InfoWindow(title: "You"),
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        passengerPosition!,
        15,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> searchPlace(String value) async {
    if (value.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    suggestions = await placesService.searchPlaces(value);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> selectPlace(dynamic place) async {
    searchController.text = place["description"];

    suggestions.clear();

    final details =
    await placesService.getPlaceDetails(
  place["place_id"],
);

if (details == null) return;

final location = details["location"];

selectedDestination = LatLng(
  location["latitude"],
  location["longitude"],
);


    if (selectedDestination == null) return;

    setState(() {});

    await drawRoute();
  }

  Future<void> drawRoute() async {
    if (passengerPosition == null || selectedDestination == null) {
      return;
    }

    final result = await routeService.getRoute(
  originLat: passengerPosition!.latitude,
  originLng: passengerPosition!.longitude,
  destLat: selectedDestination!.latitude,
  destLng: selectedDestination!.longitude,
);

if (result == null) return;

final route = result["routes"][0];

    distanceKm =
    (route["distanceMeters"] as int) / 1000;

final seconds = int.parse(
  route["duration"]
      .toString()
      .replaceAll("s", ""),
);

duration = "${(seconds / 60).ceil()} min";

    bikeFare = fareService.bikeFare(distanceKm);

economyFare =
    fareService.economyFare(distanceKm);

suvFare =
    fareService.suvFare(distanceKm);

    final encoded =
    route["polyline"]["encodedPolyline"];

final points =
    polylinePoints.decodePolyline(encoded);

routePoints = points
    .map(
      (e) => LatLng(
        e.latitude,
        e.longitude,
      ),
    )
    .toList();

polylines = {
  Polyline(
    polylineId: const PolylineId("route"),
    points: routePoints,
    color: Colors.blue,
    width: 6,
  ),
};

if (mounted) {
  setState(() {});
}
  }

    void startDriverMovement() {
    if (passengerPosition == null || selectedDestination == null) return;

    driverTimer?.cancel();

    driverPosition = passengerPosition;

    markers.removeWhere(
      (marker) => marker.markerId.value == "driver",
    );

    markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: driverPosition!,
        icon: carIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: "Driver"),
      ),
    );

    setState(() {});

    driverTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (driverPosition == null) return;

        final double lat = driverPosition!.latitude +
            (selectedDestination!.latitude - driverPosition!.latitude) *
                0.10;

        final double lng = driverPosition!.longitude +
            (selectedDestination!.longitude - driverPosition!.longitude) *
                0.10;

        driverPosition = LatLng(lat, lng);

        markers.removeWhere(
          (marker) => marker.markerId.value == "driver",
        );

        markers.add(
          Marker(
            markerId: const MarkerId("driver"),
            position: driverPosition!,
            icon: carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "Driver"),
          ),
        );

        mapController?.animateCamera(
          CameraUpdate.newLatLng(driverPosition!),
        );

        final double remaining =
            Geolocator.distanceBetween(
                  driverPosition!.latitude,
                  driverPosition!.longitude,
                  selectedDestination!.latitude,
                  selectedDestination!.longitude,
                ) /
                1000;

        if (remaining <= 0.1) {
          rideStatus = "Driver has arrived";
          timer.cancel();
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    driverTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("MyDrive"),
  centerTitle: true,
  backgroundColor: Colors.blue,
  actions: [
    IconButton(
      icon: const Icon(Icons.history),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HistoryScreen(),
          ),
        );
      },
    ),
  ],
),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) async {
              mapController = controller;

              await loadCarIcon();
              await getCurrentLocation();
            },
          ),

          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search Destination",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                ),
                onChanged: searchPlace,
              ),
            ),
          ),

          if (suggestions.isNotEmpty)
            Positioned(
              top: 85,
              left: 15,
              right: 15,
              child: Card(
                elevation: 5,
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final place = suggestions[index];

                      final text =
                          place["placePrediction"]?["text"]?["text"] ??
                              "Unknown Place";

                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(text),
                        onTap: () async {
                          searchController.text = text;

                          final placeId =
                              place["placePrediction"]["placeId"];

                          final details =
                              await placesService.getPlaceDetails(placeId);

                          if (details == null) return;

                          final location = details["location"];

                          selectedDestination = LatLng(
                            location["latitude"],
                            location["longitude"],
                          );

                          suggestions.clear();

                          markers.removeWhere(
                            (marker) =>
                                marker.markerId.value ==
                                "destination",
                          );

                          markers.add(
                            Marker(
                              markerId: const MarkerId(
                                "destination",
                              ),
                              position: selectedDestination!,
                              infoWindow: InfoWindow(
                                title: text,
                              ),
                            ),
                          );

                          mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              selectedDestination!,
                              16,
                            ),
                          );

                          await drawRoute();

                          if (mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 95,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_taxi,
                      color: Colors.blue,
                      size: 30,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        rideStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                icon: const Icon(Icons.local_taxi),
                label: const Text(
                  "Find Driver",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  if (currentPosition == null ||
                      selectedDestination == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select a destination first.",
                        ),
                      ),
                    );
                    return;
                  }

                  await drawRoute();

                  startDriverMovement();

                  if (!context.mounted) return;

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => 
                    RideBottomSheet(
  bikeFare: bikeFare,
  economyFare: economyFare,
  suvFare: suvFare,
  distance: distanceKm,
  duration: duration,
  pickup: passengerPosition!,
  destination: selectedDestination!,
  routePoints: routePoints,
),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}