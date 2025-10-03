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
      Provide comprehensive nutrition and recipe information for: ${foodName.replaceAll('_', ' ')}

      Please return the information in this exact JSON format (no additional text):
      {
        "name": "${foodName.replaceAll('_', ' ')}",
        "calories": <number>,
        "protein": <number>,
        "carbohydrates": <number>,
        "fat": <number>,
        "fiber": <number>,
        "sugar": <number>,
        "sodium": <number>,
        "servingSize": "<typical serving size>",
        "nutrients": {
          "vitaminA": "<amount>mcg",
          "vitaminC": "<amount>mg",
          "vitaminD": "<amount>mcg",
          "vitaminE": "<amount>mg",
          "vitaminK": "<amount>mcg",
          "thiamine": "<amount>mg",
          "riboflavin": "<amount>mg",
          "niacin": "<amount>mg",
          "folate": "<amount>mcg",
          "calcium": "<amount>mg",
          "iron": "<amount>mg",
          "magnesium": "<amount>mg",
          "phosphorus": "<amount>mg",
          "potassium": "<amount>mg",
          "zinc": "<amount>mg",
          "selenium": "<amount>mcg"
        },
        "dietaryInfo": {
          "isVegetarian": <true/false>,
          "isVegan": <true/false>,
          "isGlutenFree": <true/false>,
          "isDairyFree": <true/false>,
          "allergens": ["<allergen1>", "<allergen2>"],
          "dietaryFiber": "<high/medium/low>",
          "glycemicIndex": "<high/medium/low>"
        },
        "benefits": [
          "<detailed health benefit 1>",
          "<detailed health benefit 2>",
          "<detailed health benefit 3>",
          "<detailed health benefit 4>"
        ],
        "preparationTips": [
          "<cooking/preparation tip 1>",
          "<cooking/preparation tip 2>",
          "<cooking/preparation tip 3>"
        ],
        "recipe": {
          "ingredients": [
            "<ingredient 1 with amount>",
            "<ingredient 2 with amount>",
            "<ingredient 3 with amount>",
            "<ingredient 4 with amount>"
          ],
          "instructions": [
            "<step 1>",
            "<step 2>",
            "<step 3>",
            "<step 4>"
          ],
          "prepTime": "<time in minutes>",
          "cookTime": "<time in minutes>",
          "difficulty": "<Easy/Medium/Hard>",
          "servings": <number>
        },
        "source": "Gemini AI"
      }

      Provide realistic, accurate nutritional values per 100g serving. Include complete micronutrient profile, dietary classifications, and a simple but delicious recipe.
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
        'protein': 12,
        'carbohydrates': 36,
        'fat': 10,
        'fiber': 2,
        'sugar': 4,
        'sodium': 640,
        'servingSize': '1 slice (100g)',
        'nutrients': {
          'vitaminA': '15mcg',
          'vitaminC': '2mg',
          'vitaminD': '0.1mcg',
          'calcium': '200mg',
          'iron': '2.5mg',
          'magnesium': '25mg',
          'potassium': '230mg',
          'zinc': '1.2mg',
        },
        'dietaryInfo': {
          'isVegetarian': true,
          'isVegan': false,
          'isGlutenFree': false,
          'isDairyFree': false,
          'allergens': ['gluten', 'dairy'],
          'glycemicIndex': 'medium'
        },
        'benefits': [
          'Good source of calcium for strong bones and teeth',
          'Provides energy from carbohydrates for daily activities',
          'Contains lycopene from tomato sauce which has antioxidant properties',
          'Protein content supports muscle maintenance and growth'
        ],
        'preparationTips': [
          'Use whole wheat crust for more fiber and nutrients',
          'Add vegetables like bell peppers and spinach for extra vitamins',
          'Choose lean proteins like grilled chicken or turkey'
        ],
        'recipe': {
          'ingredients': [
            '200g pizza dough',
            '100ml tomato sauce',
            '150g mozzarella cheese',
            '2 tbsp olive oil',
            'Fresh basil leaves',
            'Salt and pepper to taste'
          ],
          'instructions': [
            'Preheat oven to 220°C (200°C fan)',
            'Roll out pizza dough on a floured surface',
            'Spread tomato sauce evenly over the base',
            'Add mozzarella cheese and desired toppings',
            'Bake for 12-15 minutes until golden and crispy',
            'Garnish with fresh basil before serving'
          ],
          'prepTime': '15 min',
          'cookTime': '15 min',
          'difficulty': 'Easy',
          'servings': 4
        },
        'source': 'Enhanced Nutrition Database (Fallback)'
      },
      'hamburger': {
        'name': 'Hamburger',
        'calories': 540,
        'protein': 25,
        'carbohydrates': 40,
        'fat': 31,
        'fiber': 2,
        'sugar': 5,
        'sodium': 1040,
        'servingSize': '1 burger (150g)',
        'nutrients': {
          'vitaminA': '8mcg',
          'vitaminC': '1mg',
          'vitaminD': '0.5mcg',
          'calcium': '120mg',
          'iron': '4mg',
          'magnesium': '35mg',
          'potassium': '380mg',
          'zinc': '5mg',
        },
        'dietaryInfo': {
          'isVegetarian': false,
          'isVegan': false,
          'isGlutenFree': false,
          'isDairyFree': false,
          'allergens': ['gluten', 'dairy'],
          'glycemicIndex': 'medium'
        },
        'benefits': [
          'High protein content supports muscle building and repair',
          'Good source of iron for healthy blood and oxygen transport',
          'Provides B-vitamins essential for energy metabolism',
          'Contains zinc which supports immune system function'
        ],
        'preparationTips': [
          'Choose lean ground beef (90% lean) to reduce fat content',
          'Add lettuce, tomato, and onions for extra vitamins and fiber',
          'Use whole grain buns for additional nutrients and fiber'
        ],
        'recipe': {
          'ingredients': [
            '150g lean ground beef',
            '1 hamburger bun',
            '1 slice cheese',
            '2 lettuce leaves',
            '2 tomato slices',
            '1 tbsp mayonnaise',
            'Salt and pepper to taste'
          ],
          'instructions': [
            'Season ground beef with salt and pepper',
            'Form into a patty slightly larger than the bun',
            'Cook in a hot pan for 3-4 minutes per side',
            'Add cheese in the last minute of cooking',
            'Toast the bun lightly',
            'Assemble with lettuce, tomato, and condiments'
          ],
          'prepTime': '10 min',
          'cookTime': '8 min',
          'difficulty': 'Easy',
          'servings': 1
        },
        'source': 'Enhanced Nutrition Database (Fallback)'
      },
      'chicken curry': {
        'name': 'Chicken Curry',
        'calories': 165,
        'protein': 22,
        'carbohydrates': 8,
        'fat': 6,
        'fiber': 2,
        'sugar': 4,
        'sodium': 420,
        'servingSize': '1 cup (250ml)',
        'nutrients': {
          'vitaminA': '95mcg',
          'vitaminC': '12mg',
          'vitaminD': '0.3mcg',
          'calcium': '45mg',
          'iron': '1.8mg',
          'magnesium': '28mg',
          'potassium': '340mg',
          'zinc': '1.5mg',
        },
        'dietaryInfo': {
          'isVegetarian': false,
          'isVegan': false,
          'isGlutenFree': true,
          'isDairyFree': true,
          'allergens': [],
          'glycemicIndex': 'low'
        },
        'benefits': [
          'High-quality protein supports muscle development and repair',
          'Turmeric and spices provide anti-inflammatory compounds',
          'Low in carbohydrates, suitable for weight management',
          'Rich in vitamins and minerals from vegetables and spices'
        ],
        'preparationTips': [
          'Use coconut milk for creaminess without dairy',
          'Add vegetables like bell peppers and spinach for extra nutrition',
          'Serve with brown rice or quinoa for complete nutrition'
        ],
        'recipe': {
          'ingredients': [
            '300g chicken breast, cubed',
            '1 onion, diced',
            '2 cloves garlic, minced',
            '1 tbsp curry powder',
            '200ml coconut milk',
            '1 can diced tomatoes',
            '2 tbsp vegetable oil'
          ],
          'instructions': [
            'Heat oil in a large pan over medium heat',
            'Cook onion and garlic until fragrant',
            'Add chicken and cook until browned',
            'Stir in curry powder and cook for 1 minute',
            'Add tomatoes and coconut milk, simmer 15 minutes',
            'Season with salt and pepper to taste'
          ],
          'prepTime': '15 min',
          'cookTime': '25 min',
          'difficulty': 'Medium',
          'servings': 4
        },
        'source': 'Enhanced Nutrition Database (Fallback)'
      }
    };

    // Get nutrition info or use generic fallback
    final normalizedName = foodName.toLowerCase().replaceAll(' ', '_');
    return nutritionDatabase[normalizedName] ?? {
      'name': foodName,
      'calories': 200,
      'protein': 8,
      'carbohydrates': 30,
      'fat': 5,
      'fiber': 3,
      'sugar': 5,
      'sodium': 400,
      'servingSize': '1 serving (100g)',
      'nutrients': {
        'vitaminA': '10mcg',
        'vitaminC': '5mg',
        'vitaminD': '0.2mcg',
        'calcium': '100mg',
        'iron': '2mg',
        'magnesium': '20mg',
        'potassium': '250mg',
        'zinc': '1mg',
      },
      'dietaryInfo': {
        'isVegetarian': false,
        'isVegan': false,
        'isGlutenFree': false,
        'isDairyFree': false,
        'allergens': [],
        'glycemicIndex': 'medium'
      },
      'benefits': [
        'Provides essential nutrients for daily energy needs',
        'Source of protein for muscle maintenance',
        'Contains vitamins and minerals for overall health',
        'Supports a balanced and nutritious diet'
      ],
      'preparationTips': [
        'Cook thoroughly to ensure food safety',
        'Pair with vegetables for additional nutrients',
        'Use healthy cooking methods like grilling or steaming'
      ],
      'recipe': {
        'ingredients': [
          'Main ingredient as needed',
          'Salt and pepper to taste',
          'Cooking oil (1-2 tbsp)',
          'Optional seasonings'
        ],
        'instructions': [
          'Prepare ingredients by washing and cutting as needed',
          'Heat cooking oil in a pan over medium heat',
          'Cook the main ingredient thoroughly',
          'Season with salt, pepper, and desired spices',
          'Serve hot with your favorite sides'
        ],
        'prepTime': '10 min',
        'cookTime': '15 min',
        'difficulty': 'Easy',
        'servings': 2
      },
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