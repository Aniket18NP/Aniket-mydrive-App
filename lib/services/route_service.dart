import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class RouteService {
  Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );

    final body = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": originLat,
            "longitude": originLng,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destLat,
            "longitude": destLng,
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "languageCode": "en-US",
      "units": "METRIC",
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": AppConstants.googleApiKey,
        "X-Goog-FieldMask":
            "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline",
      },
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
print("Response: ${response.body}");

if (response.statusCode == 200) {
  return jsonDecode(response.body);
}

return null;
  }
}