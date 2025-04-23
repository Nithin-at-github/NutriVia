import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodService {
  final String appId = "97b89e15";
  final String appKey = "42b13177910380eadf7116a4bd475dbc";
  final String baseUrl = "https://api.edamam.com/api/food-database/v2/parser";

  Future<List<dynamic>> fetchFoods(
    String query,
    String region,
    String? diet,
    List<String> restrictions,
  ) async {
    // Construct search query
    String searchQuery = "$query $region";
    String url = "$baseUrl?app_id=$appId&app_key=$appKey&ingr=$searchQuery";

    // Add diet type if available
    if (diet != null && diet.isNotEmpty) {
      url += "&diet=$diet"; // Example: &diet=low-carb
    }

    // Add health restrictions
    for (String restriction in restrictions) {
      url += "&health=$restriction"; // Example: &health=gluten-free
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['hints'] ?? [];
    } else {
      throw Exception("Failed to fetch foods");
    }
  }
}
