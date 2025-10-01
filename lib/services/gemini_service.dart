import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Uncomment when using environment variables

/// Nutrition data returned by Gemini API
class NutritionData {
  final double calories;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double proteinG;

  const NutritionData({
    required this.calories,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.proteinG,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    try {
      return NutritionData(
        calories: _parseDouble(json['calories']),
        carbsG: _parseDouble(json['carbs_g']),
        fatG: _parseDouble(json['fat_g']),
        fiberG: _parseDouble(json['fiber_g']),
        proteinG: _parseDouble(json['protein_g']),
      );
    } catch (e) {
      throw FormatException('Invalid nutrition data format: $e');
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) throw FormatException('Missing required nutrition value');
    
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) throw FormatException('Invalid number format: $value');
      return parsed;
    }
    
    throw FormatException('Invalid data type for nutrition value: ${value.runtimeType}');
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'protein_g': proteinG,
    };
  }

  @override
  String toString() {
    return 'NutritionData(calories: $calories, carbs: ${carbsG}g, fat: ${fatG}g, fiber: ${fiberG}g, protein: ${proteinG}g)';
  }
}

/// Service for getting nutrition estimates using Google's Gemini API
class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  
  /// Get nutrition estimates for a given food name
  /// 
  /// [foodName] - Name of the food item to analyze
  /// [apiKey] - Your Gemini API key
  /// 
  /// Example usage with environment variables:
  /// ```dart
  /// // 1. Add flutter_dotenv to pubspec.yaml dependencies
  /// // 2. Create .env file in project root with:
  /// //    GEMINI_API_KEY=your_api_key_here
  /// // 3. Add .env to assets in pubspec.yaml:
  /// //    assets:
  /// //      - .env
  /// // 4. Initialize in main():
  /// //    await dotenv.load(fileName: ".env");
  /// // 5. Use in your code:
  /// //    final apiKey = dotenv.env['GEMINI_API_KEY']!;
  /// //    final nutrition = await GeminiService.getNutritionEstimates('apple', apiKey);
  /// ```
  /// 
  /// Alternative: Pass API key directly (not recommended for production):
  /// ```dart
  /// final nutrition = await GeminiService.getNutritionEstimates(
  ///   'banana', 
  ///   'your_api_key_here'
  /// );
  /// ```
  /// 
  /// Returns [NutritionData] with estimated nutritional values per 100g serving
  /// Throws [ArgumentError] if parameters are invalid
  /// Throws [HttpException] if API request fails
  /// Throws [FormatException] if response cannot be parsed
  static Future<NutritionData> getNutritionEstimates(
    String foodName,
    String apiKey,
  ) async {
    // Validate inputs
    if (foodName.trim().isEmpty) {
      throw ArgumentError('Food name cannot be empty');
    }
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }

    try {
      // Build the prompt for accurate nutrition estimation
      final prompt = _buildNutritionPrompt(foodName.trim());
      
      // Create request payload
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1, // Low temperature for consistent, factual responses
          'topK': 1,
          'topP': 0.8,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      // Handle HTTP errors
      if (response.statusCode != 200) {
        final errorBody = response.body;
        debugPrint('Gemini API Error (${response.statusCode}): $errorBody');
        
        if (response.statusCode == 401) {
          throw Exception('Invalid API key. Please check your Gemini API key.');
        } else if (response.statusCode == 403) {
          throw Exception('API key does not have permission to access Gemini API.');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else {
          throw Exception('Gemini API request failed: ${response.statusCode} - $errorBody');
        }
      }

      // Parse response
      final responseData = json.decode(response.body);
      
      // Extract generated text
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw FormatException('No response candidates from Gemini API');
      }

      final content = candidates[0]['content'];
      if (content == null) {
        throw FormatException('No content in Gemini API response');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw FormatException('No parts in Gemini API response content');
      }

      final generatedText = parts[0]['text'] as String?;
      if (generatedText == null || generatedText.trim().isEmpty) {
        throw FormatException('Empty response from Gemini API');
      }

      // Extract and parse JSON from the response
      final nutritionData = _parseNutritionFromResponse(generatedText);
      
      return nutritionData;
    } catch (e) {
      debugPrint('Error in getNutritionEstimates: $e');
      rethrow;
    }
  }

  /// Builds a detailed prompt for nutrition estimation
  static String _buildNutritionPrompt(String foodName) {
    return '''
Analyze the nutritional content of "$foodName" and provide estimates per 100 grams.

Please respond with ONLY a valid JSON object containing the following nutritional information:
- calories: Total calories (number)
- carbs_g: Total carbohydrates in grams (number)
- fat_g: Total fat in grams (number)
- fiber_g: Dietary fiber in grams (number)
- protein_g: Total protein in grams (number)

Important guidelines:
1. Provide realistic estimates based on USDA or similar nutritional databases
2. If the food item is generic (like "apple"), use average values for common varieties
3. For prepared foods, estimate based on typical recipes and ingredients
4. All values should be numeric (not strings)
5. Use decimal numbers where appropriate
6. Do not include any text outside the JSON object
7. Ensure the JSON is properly formatted and valid

Example response format:
{
  "calories": 52,
  "carbs_g": 14.0,
  "fat_g": 0.2,
  "fiber_g": 2.4,
  "protein_g": 0.3
}

Food item to analyze: "$foodName"
''';
  }

  /// Parses nutrition data from Gemini's text response
  static NutritionData _parseNutritionFromResponse(String responseText) {
    try {
      // Find JSON in the response (handle cases where there might be extra text)
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw FormatException('No JSON object found in response: $responseText');
      }

      final jsonString = jsonMatch.group(0)!;
      final jsonData = json.decode(jsonString);

      if (jsonData is! Map<String, dynamic>) {
        throw FormatException('Response is not a JSON object');
      }

      // Validate required fields
      final requiredFields = ['calories', 'carbs_g', 'fat_g', 'fiber_g', 'protein_g'];
      final missingFields = requiredFields.where((field) => !jsonData.containsKey(field)).toList();
      
      if (missingFields.isNotEmpty) {
        throw FormatException('Missing required nutrition fields: ${missingFields.join(', ')}');
      }

      // Create and validate NutritionData object
      final nutritionData = NutritionData.fromJson(jsonData);
      
      // Basic validation of nutrition values
      _validateNutritionValues(nutritionData);
      
      return nutritionData;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to parse nutrition data: $e');
    }
  }

  /// Validates that nutrition values are reasonable
  static void _validateNutritionValues(NutritionData data) {
    // Check for negative values
    if (data.calories < 0 || data.carbsG < 0 || data.fatG < 0 || 
        data.fiberG < 0 || data.proteinG < 0) {
      throw FormatException('Nutrition values cannot be negative');
    }

    // Check for unreasonably high values (per 100g)
    if (data.calories > 900) { // Even pure fat has ~900 calories per 100g
      throw FormatException('Calories value seems unreasonably high: ${data.calories}');
    }
    
    if (data.carbsG > 100 || data.fatG > 100 || data.proteinG > 100) {
      throw FormatException('Macronutrient values cannot exceed 100g per 100g food');
    }
    
    if (data.fiberG > 50) { // Very high fiber foods max out around 40-50g per 100g
      throw FormatException('Fiber value seems unreasonably high: ${data.fiberG}');
    }

    // Check that fiber doesn't exceed total carbs
    if (data.fiberG > data.carbsG) {
      throw FormatException('Fiber cannot exceed total carbohydrates');
    }
  }
}

/// Custom exception for HTTP-related errors
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  const HttpException(this.message, [this.statusCode]);

  @override
  String toString() => 'HttpException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}