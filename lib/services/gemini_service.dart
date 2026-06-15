import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RestaurantSpot {
  final String name;
  final String address;
  final String specialty;

  RestaurantSpot({
    required this.name,
    required this.address,
    required this.specialty,
  });

  factory RestaurantSpot.fromJson(Map<String, dynamic> json) {
    return RestaurantSpot(
      name: json['name']?.toString() ?? json['restaurantName']?.toString() ?? 'Unknown Restaurant',
      address: json['address']?.toString() ?? json['location']?.toString() ?? 'Nearby',
      specialty: json['specialty']?.toString() ?? json['recommendedDish']?.toString() ?? '',
    );
  }
}

class FoodScanResult {
  final String foodName;
  final bool isFood;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final String description;
  final List<RestaurantSpot> restaurants;

  FoodScanResult({
    required this.foodName,
    required this.isFood,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.description,
    required this.restaurants,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return FoodScanResult(
      foodName: json['foodName']?.toString() ?? 'Unknown Food',
      isFood: json['isFood'] as bool? ?? false,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: toDouble(json['protein'] ?? json['proteins']),
      fat: toDouble(json['fat'] ?? json['fats']),
      carbs: toDouble(json['carbs'] ?? json['carbohydrates']),
      description: json['description']?.toString() ?? '',
      restaurants: (json['restaurants'] as List?)
              ?.map((item) => RestaurantSpot.fromJson(item as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class GeminiService {
  static Future<FoodScanResult> scanFoodImage({
    required Uint8List imageBytes,
    required String apiKey,
    String? locationName,
  }) async {
    final models = [
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-3.5-flash',
      'gemini-1.5-flash',
    ];

    dynamic lastError;

    for (final model in models) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

        final base64Image = base64Encode(imageBytes);

        String prompt = 'Analyze this image and identify the food item. '
            'If the image does not contain any food, set isFood to false. '
            'Provide the response as a single, valid JSON object with the following fields: '
            '"foodName" (string, name of the food, supporting all global and Pakistani cuisines such as Biryani, Karahi, Pulao, Nihari, Halwa Puri, Paratha, Samosa, burgers, pizzas, pastas, etc.), '
            '"isFood" (boolean, true if it is a food item, false otherwise), '
            '"calories" (integer, estimation of calories per standard serving in kcal), '
            '"protein" (number, estimation of protein in grams per serving), '
            '"fat" (number, estimation of fat in grams per serving), '
            '"carbs" (number, estimation of carbohydrates in grams per serving), '
            '"description" (string, a brief 1-2 sentence description explaining the dish and its nutritional composition), ';

        if (locationName != null && locationName.isNotEmpty) {
          prompt += '"restaurants" (array of objects, containing the top 3-4 best local restaurants/spots to eat this food item (or variations of it, e.g. Zinger burger if a burger is scanned) in or near the location "$locationName". Each object must have "name" (string, name of the restaurant), "address" (string, the branch name, street, or area name in "$locationName"), and "specialty" (string, the specific popular version of this food they are famous for)). ';
        } else {
          prompt += '"restaurants" (array of objects, containing the top 3-4 famous spots/chains to eat this food. Each object must have "name" (string), "address" (string, e.g., "Main branches / Nationwide"), and "specialty" (string)). ';
        }

        prompt += 'Ensure the JSON output is strictly formatted. Do not wrap the JSON object in markdown formatting or "```json" blocks. Return only raw, valid JSON.';

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('No analysis result received from Gemini.');
          }
          final content = candidates[0]['content'];
          if (content == null) {
            throw Exception('Content not found in API response.');
          }
          final parts = content['parts'] as List?;
          if (parts == null || parts.isEmpty) {
            throw Exception('Parts not found in API response.');
          }
          String resultText = parts[0]['text']?.toString() ?? '';

          resultText = resultText.trim();
          if (resultText.startsWith('```')) {
            resultText = resultText.replaceAll(RegExp(r'^```(json)?'), '');
            resultText = resultText.replaceAll(RegExp(r'```$'), '');
            resultText = resultText.trim();
          }

          final jsonMap = jsonDecode(resultText) as Map<String, dynamic>;
          return FoodScanResult.fromJson(jsonMap);
        } else {
          final bodyJson = jsonDecode(response.body);
          final errorMsg = bodyJson['error']?['message'] ?? 'Unknown error';
          if (response.statusCode == 404 || errorMsg.toString().contains('not found')) {
            lastError = 'Model $model not found: $errorMsg';
            continue;
          }
          throw Exception('API call failed with status ${response.statusCode}: $errorMsg');
        }
      } catch (e) {
        lastError = e;
        // Continue to check other models
      }
    }

    throw Exception('Failed to analyze food with all available models. Last error: $lastError');
  }
}
