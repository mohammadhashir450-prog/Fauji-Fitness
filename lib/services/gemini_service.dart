import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FoodScanResult {
  final String foodName;
  final bool isFood;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final String description;

  FoodScanResult({
    required this.foodName,
    required this.isFood,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.description,
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
    );
  }
}

class GeminiService {
  static Future<FoodScanResult> scanFoodImage({
    required Uint8List imageBytes,
    required String apiKey,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final base64Image = base64Encode(imageBytes);

    const prompt = 'Analyze this image and identify the food item. '
        'If the image does not contain any food, set isFood to false. '
        'Provide the response as a single, valid JSON object with the following fields: '
        '"foodName" (string, name of the food, supporting all global and Pakistani cuisines such as Biryani, Karahi, Pulao, Nihari, Halwa Puri, Paratha, Samosa, burgers, pizzas, pastas, etc.), '
        '"isFood" (boolean, true if it is a food item, false otherwise), '
        '"calories" (integer, estimation of calories per standard serving in kcal), '
        '"protein" (number, estimation of protein in grams per serving), '
        '"fat" (number, estimation of fat in grams per serving), '
        '"carbs" (number, estimation of carbohydrates in grams per serving), '
        '"description" (string, a brief 1-2 sentence description explaining the dish and its nutritional composition). '
        'Ensure the JSON output is strictly formatted. Do not wrap the JSON object in markdown formatting or "```json" blocks. Return only raw, valid JSON.';

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

    if (response.statusCode != 200) {
      throw Exception('API call failed: ${response.statusCode}\n${response.body}');
    }

    final data = jsonDecode(response.body);

    // Wait, let's parse candidates[0].content.parts[0].text properly
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

    // Clean up markdown block wraps if Gemini returns them
    resultText = resultText.trim();
    if (resultText.startsWith('```')) {
      // remove starting ```json or ```
      resultText = resultText.replaceAll(RegExp(r'^```(json)?'), '');
      // remove ending ```
      resultText = resultText.replaceAll(RegExp(r'```$'), '');
      resultText = resultText.trim();
    }

    try {
      final jsonMap = jsonDecode(resultText) as Map<String, dynamic>;
      return FoodScanResult.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse nutrition details from API response: $e\nResponse: $resultText');
    }
  }
}
