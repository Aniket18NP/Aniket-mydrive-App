import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class PlacesService {
 Future<List<dynamic>> searchPlaces(String query) async {
  if (query.isEmpty) return [];

  final url = Uri.parse(
    "https://places.googleapis.com/v1/places:autocomplete",
  );

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": AppConstants.googleApiKey,
    },
    body: jsonEncode({
      "input": query,
    }),
  );

  print("Status Code: ${response.statusCode}");
  print("Response: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["suggestions"] ?? [];
  }

  return [];
}

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      "https://places.googleapis.com/v1/places/$placeId",
    );

    final response = await http.get(
      url,
      headers: {
        "X-Goog-Api-Key": AppConstants.googleApiKey,
        "X-Goog-FieldMask":
            "location,displayName",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}