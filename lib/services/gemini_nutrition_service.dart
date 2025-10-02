import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class GeminiNutritionService {
  static GenerativeModel? _model;
  static bool _isInitialized = false;
  static String? _apiKey;

  /// Initialize Gemini API service
  static Future<bool> initialize() async {
    try {
      debugPrint('Initializing Gemini Nutrition Service...');

      // Load API key from environment or assets
      _apiKey = await _loadApiKey();
      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('Gemini API key not found');
        return false;
      }

      // Initialize Gemini model
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          topP: 0.8,
          maxOutputTokens: 1000,
        ),
      );

      _isInitialized = true;
      debugPrint('Gemini Nutrition Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing Gemini service: $e');
      return false;
    }
  }

  /// Load API key from environment or config
  static Future<String?> _loadApiKey() async {
    try {
      // Try to load from assets/.env file
      final String envContent = await rootBundle.loadString('assets/.env');
      final Map<String, String> envMap = {};
      
      for (String line in envContent.split('\n')) {
        line = line.trim();
        if (line.isNotEmpty && !line.startsWith('#') && line.contains('=')) {
          final List<String> parts = line.split('=');
          if (parts.length >= 2) {
            envMap[parts[0].trim()] = parts.sublist(1).join('=').trim();
          }
        }
      }
      
      return envMap['GEMINI_API_KEY'];
    } catch (e) {
      debugPrint('Error loading API key: $e');
      // In production, you might want to load from secure storage
      return null;
    }
  }

  /// Get detailed nutrition information for food
  static Future<Map<String, dynamic>> getNutritionInfo(String foodName) async {
    if (!_isInitialized || _model == null) {
      debugPrint('Gemini service not initialized, using fallback');
      return _getFallbackNutrition(foodName);
    }

    try {
      final prompt = '''
      Provide detailed nutritional information for: $foodName

      Please return the information in this exact JSON format (no additional text):
      {
        "name": "$foodName",
        "calories": <number>,
        "servingSize": "<serving size>",
        "nutrients": {
          "protein": "<amount>g",
          "carbohydrates": "<amount>g",
          "fat": "<amount>g",
          "fiber": "<amount>g",
          "sugar": "<amount>g",
          "sodium": "<amount>mg",
          "cholesterol": "<amount>mg",
          "vitaminC": "<amount>mg",
          "calcium": "<amount>mg",
          "iron": "<amount>mg"
        },
        "healthBenefits": [
          "<benefit 1>",
          "<benefit 2>",
          "<benefit 3>"
        ],
        "cookingTips": [
          "<tip 1>",
          "<tip 2>"
        ],
        "source": "Gemini AI"
      }

      Provide realistic, accurate nutritional values for a typical serving.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      if (response.text != null) {
        // Try to parse JSON response
        final jsonStr = response.text!.trim();
        final Map<String, dynamic> nutritionData = json.decode(jsonStr);
        
        debugPrint('Gemini nutrition info retrieved successfully');
        return nutritionData;
      } else {
        debugPrint('Empty response from Gemini');
        return _getFallbackNutrition(foodName);
      }
    } catch (e) {
      debugPrint('Error getting nutrition info from Gemini: $e');
      return _getFallbackNutrition(foodName);
    }
  }

  /// Get food recipe suggestions from Gemini
  static Future<Map<String, dynamic>?> getRecipeSuggestion(String foodName) async {
    if (!_isInitialized || _model == null) {
      debugPrint('Gemini service not initialized');
      return null;
    }

    try {
      final prompt = '''
      Provide a simple recipe for: $foodName

      Please return the information in this exact JSON format:
      {
        "name": "$foodName",
        "prepTime": "<time>",
        "cookTime": "<time>",
        "servings": <number>,
        "difficulty": "<Easy/Medium/Hard>",
        "ingredients": [
          "<ingredient 1>",
          "<ingredient 2>",
          "<ingredient 3>"
        ],
        "instructions": [
          "<step 1>",
          "<step 2>",
          "<step 3>"
        ],
        "tips": [
          "<tip 1>",
          "<tip 2>"
        ]
      }

      Keep the recipe simple and practical for home cooking.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      if (response.text != null) {
        final jsonStr = response.text!.trim();
        final Map<String, dynamic> recipeData = json.decode(jsonStr);
        debugPrint('Gemini recipe retrieved successfully');
        return recipeData;
      }
    } catch (e) {
      debugPrint('Error getting recipe from Gemini: $e');
    }
    
    return null;
  }

  /// Fallback nutrition information when Gemini is not available
  static Map<String, dynamic> _getFallbackNutrition(String foodName) {
    // Enhanced fallback with more detailed nutrition info
    final Map<String, Map<String, dynamic>> nutritionDatabase = {
      'pizza': {
        'name': 'Pizza',
        'calories': 285,
        'servingSize': '1 slice (100g)',
        'nutrients': {
          'protein': '12g',
          'carbohydrates': '36g',
          'fat': '10g',
          'fiber': '2.3g',
          'sugar': '3.6g',
          'sodium': '640mg',
          'cholesterol': '17mg',
          'vitaminC': '2mg',
          'calcium': '200mg',
          'iron': '2.5mg'
        },
        'healthBenefits': [
          'Good source of calcium and protein',
          'Provides energy from carbohydrates',
          'Contains lycopene from tomato sauce'
        ],
        'cookingTips': [
          'Use whole wheat crust for more fiber',
          'Add vegetables for extra nutrients'
        ],
        'source': 'Nutrition Database (Fallback)'
      },
      'hamburger': {
        'name': 'Hamburger',
        'calories': 540,
        'servingSize': '1 burger (150g)',
        'nutrients': {
          'protein': '25g',
          'carbohydrates': '40g',
          'fat': '31g',
          'fiber': '2g',
          'sugar': '5g',
          'sodium': '1040mg',
          'cholesterol': '80mg',
          'vitaminC': '1mg',
          'calcium': '120mg',
          'iron': '4mg'
        },
        'healthBenefits': [
          'High protein content for muscle building',
          'Iron for healthy blood',
          'B-vitamins for energy metabolism'
        ],
        'cookingTips': [
          'Choose lean ground beef',
          'Add lettuce and tomato for vitamins'
        ],
        'source': 'Nutrition Database (Fallback)'
      }
    };

    // Get nutrition info or use generic fallback
    final normalizedName = foodName.toLowerCase().replaceAll(' ', '_');
    return nutritionDatabase[normalizedName] ?? {
      'name': foodName,
      'calories': 200,
      'servingSize': '1 serving (100g)',
      'nutrients': {
        'protein': '8g',
        'carbohydrates': '30g',
        'fat': '5g',
        'fiber': '3g',
        'sugar': '5g',
        'sodium': '400mg',
        'cholesterol': '10mg',
        'vitaminC': '5mg',
        'calcium': '100mg',
        'iron': '2mg'
      },
      'healthBenefits': [
        'Provides essential nutrients',
        'Source of energy',
        'Supports healthy diet'
      ],
      'cookingTips': [
        'Cook thoroughly',
        'Pair with vegetables'
      ],
      'source': 'Generic Nutrition (Fallback)'
    };
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose resources
  static void dispose() {
    _model = null;
    _apiKey = null;
    _isInitialized = false;
  }
}