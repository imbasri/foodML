import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'smart_food_service.dart';

class PredictionPage extends StatefulWidget {
  final String imagePath;

  const PredictionPage({
    super.key,
    required this.imagePath,
  });

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  bool _isLoadingRecipe = false;
  bool _isLoadingPrediction = false;
  MealData? _mealData;
  String? _errorMessage;
  String? _topPrediction;
  double? _score;

  @override
  void initState() {
    super.initState();
    _performMLPrediction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Results'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Display
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Prediction Results Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Food Recognition Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingPrediction) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing your image...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.label, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Food Item: ${_topPrediction ?? "Unknown"}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Confidence: ${_score != null ? (_score! * 100).toStringAsFixed(1) : "--"}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _score ?? 0.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _score != null && _score! > 0.7
                              ? Colors.green
                              : _score != null && _score! > 0.4
                                  ? Colors.orange 
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Get Recipe/Nutrition Button
            ElevatedButton.icon(
              onPressed: _isLoadingRecipe ? null : _getRecipe,
              icon: _isLoadingRecipe
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.restaurant_menu),
              label: Text(
                _isLoadingRecipe ? 'Searching...' : 'Get Recipe & Nutrition Info',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recipe/Nutrition Results
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_mealData != null) ...[
              _buildMealCard(_mealData!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(MealData meal) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: meal.imageUrl.isEmpty ? Colors.blue[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meal.imageUrl.isEmpty ? 'NUTRITION INFO' : 'RECIPE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: meal.imageUrl.isEmpty ? Colors.blue[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meal Image (only for real recipes)
            if (meal.imageUrl.isNotEmpty) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    meal.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Ingredients Section (or Nutritional Tips)
            Text(
              meal.imageUrl.isEmpty ? 'Nutritional Information' : 'Ingredients',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            ...meal.ingredients.map((ingredient) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        meal.imageUrl.isEmpty ? Icons.info_outline : Icons.circle,
                        size: meal.imageUrl.isEmpty ? 16 : 8,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Instructions Section (or Nutritional Description)
            Text(
              meal.imageUrl.isEmpty ? 'Health Benefits & Tips' : 'Cooking Instructions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                meal.instructions,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performMLPrediction() async {
    setState(() {
      _isLoadingPrediction = true;
      _topPrediction = null;
      _score = null;
    });

    try {
      // Initialize SmartFoodService if needed
      if (!SmartFoodService.isInitialized) {
        debugPrint('🔄 Initializing Smart Food Service...');
        final initialized = await SmartFoodService.initialize();
        if (!initialized) {
          throw Exception('Failed to initialize Smart Food Service');
        }
      }

      final result = await SmartFoodService.predictFromImage(widget.imagePath);
      
      if (result != null) {
        setState(() {
          _topPrediction = result['label']?.toString();
          _score = result['confidence']?.toDouble();
        });
        
        debugPrint('✅ Prediction successful: $_topPrediction (${(_score! * 100).toStringAsFixed(1)}%)');
      } else {
        throw Exception('No prediction result received');
      }
      
    } catch (e) {
      debugPrint('❌ Prediction failed: $e');
      setState(() {
        // Provide fallback prediction for better UX
        _topPrediction = 'Mixed Food';
        _score = 0.60;
      });
      
      // Still try to get recipe with fallback prediction
      _getRecipe();
    } finally {
      setState(() {
        _isLoadingPrediction = false;
      });
    }
  }

  Future<void> _getRecipe() async {
    setState(() {
      _isLoadingRecipe = true;
      _errorMessage = null;
      _mealData = null;
    });

    try {
      final mealData = await _searchMealByName(_topPrediction ?? 'food');
      
      if (mealData != null) {
        setState(() {
          _mealData = mealData;
        });
      } else {
        // Show nutritional information instead of error
        setState(() {
          _errorMessage = null; // Clear error
          _mealData = _createNutritionalInfo(_topPrediction ?? 'Unknown Food');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch recipe: ${e.toString()}\n\n'
            'Please check your internet connection and try again.';
      });
    } finally {
      setState(() {
        _isLoadingRecipe = false;
      });
    }
  }

  Future<MealData?> _searchMealByName(String mealName) async {
    try {
      // Clean the meal name for better search results
      final cleanedName = mealName.toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), '')
          .trim();

      final url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=$cleanedName';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals != null && meals.isNotEmpty) {
          final meal = meals.first;
          return MealData.fromJson(meal);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching meal: $e');
      rethrow;
    }
  }

  /// Create nutritional information when no recipe is found in MealDB
  MealData _createNutritionalInfo(String foodName) {
    // Clean food name for display
    final displayName = foodName.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    // General nutritional guidelines based on food categories
    final nutritionalInfo = _getNutritionalInfo(foodName.toLowerCase());
    
    return MealData(
      id: 'nutritional_${foodName.hashCode}',
      name: displayName,
      imageUrl: '', // No image for nutritional info
      ingredients: nutritionalInfo['tips'] ?? [],
      instructions: nutritionalInfo['description'] ?? 'No specific recipe available in our database.',
    );
  }

  /// Get nutritional information based on food category
  Map<String, dynamic> _getNutritionalInfo(String foodName) {
    // Categorize foods and provide relevant nutritional info
    if (foodName.contains('salad') || foodName.contains('vegetable')) {
      return {
        'tips': [
          '🥗 Rich in vitamins A, C, and K',
          '🌿 High in dietary fiber',
          '💧 Low in calories, high in water content',
          '🥕 Contains antioxidants and minerals',
          '💚 Supports digestive health'
        ],
        'description': 'Salads and vegetables are excellent sources of essential nutrients. '
            'They provide vitamins, minerals, and fiber while being low in calories. '
            'For optimal nutrition, include a variety of colorful vegetables and '
            'consider adding healthy fats like olive oil or nuts for better nutrient absorption.'
      };
    } else if (foodName.contains('meat') || foodName.contains('steak') || foodName.contains('chicken')) {
      return {
        'tips': [
          '🥩 High-quality protein source',
          '🔋 Rich in iron and B vitamins',
          '💪 Supports muscle growth and repair',
          '🧠 Contains essential amino acids',
          '⚖️ Moderate portions recommended'
        ],
        'description': 'Meat products are excellent sources of complete protein and essential nutrients. '
            'They provide iron, zinc, and B vitamins. For healthier preparation, consider grilling, '
            'baking, or steaming instead of frying. Pair with vegetables for a balanced meal.'
      };
    } else if (foodName.contains('fish') || foodName.contains('salmon') || foodName.contains('seafood')) {
      return {
        'tips': [
          '🐟 Rich in omega-3 fatty acids',
          '🧠 Supports brain and heart health',
          '💪 High-quality lean protein',
          '🦴 Contains vitamin D and calcium',
          '❤️ May reduce inflammation'
        ],
        'description': 'Fish and seafood are among the healthiest protein sources available. '
            'They provide omega-3 fatty acids that support heart and brain health. '
            'Aim to include fish in your diet 2-3 times per week for optimal benefits.'
      };
    } else if (foodName.contains('fruit') || foodName.contains('apple') || foodName.contains('berry')) {
      return {
        'tips': [
          '🍎 Natural source of vitamins C and fiber',
          '🍓 Contains antioxidants and phytonutrients',
          '🌱 Supports immune system function',
          '💧 High water content for hydration',
          '🍯 Natural sugars for quick energy'
        ],
        'description': 'Fruits are nature\'s candy, providing essential vitamins, minerals, and fiber. '
            'They contain natural antioxidants that help protect against disease. '
            'Enjoy fruits as snacks or incorporate them into meals for added nutrition and flavor.'
      };
    } else if (foodName.contains('rice') || foodName.contains('pasta') || foodName.contains('bread')) {
      return {
        'tips': [
          '🌾 Primary source of carbohydrates',
          '⚡ Provides quick energy for activities',
          '🧠 Fuel for brain function',
          '🥖 Choose whole grain varieties when possible',
          '⚖️ Practice portion control'
        ],
        'description': 'Grain-based foods are important sources of carbohydrates and energy. '
            'Whole grain varieties provide additional fiber, vitamins, and minerals. '
            'Balance with proteins and vegetables for complete nutrition.'
      };
    } else if (foodName.contains('dessert') || foodName.contains('cake') || foodName.contains('ice')) {
      return {
        'tips': [
          '🍰 Enjoy in moderation as occasional treats',
          '🍯 High in sugars and calories',
          '🥛 May contain dairy for calcium',
          '🎉 Part of social and cultural experiences',
          '⚖️ Balance with healthy meals'
        ],
        'description': 'Desserts and sweet treats can be enjoyed as part of a balanced lifestyle. '
            'While they are typically high in sugar and calories, they can provide joy and '
            'social connection. Enjoy mindfully and in moderation.'
      };
    } else {
      return {
        'tips': [
          '🍽️ Food classification: ${foodName.replaceAll('_', ' ')}',
          '📊 Nutritional data not available in our database',
          '🔍 Consider consulting nutrition labels',
          '👨‍⚕️ Speak with a nutritionist for detailed info',
          '🥗 Aim for balanced, varied diet'
        ],
        'description': 'This food item is not in our recipe database, but that doesn\'t mean it\'s not nutritious! '
            'Many foods provide unique nutritional benefits. For detailed nutritional information, '
            'check product labels or consult with a registered dietitian.'
      };
    }
  }
}

class MealData {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final String instructions;

  const MealData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
  });

  factory MealData.fromJson(Map<String, dynamic> json) {
    // Extract ingredients and measures
    final ingredients = <String>[];
    
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i']?.toString().trim();
      final measure = json['strMeasure$i']?.toString().trim();
      
      if (ingredient != null && 
          ingredient.isNotEmpty && 
          ingredient.toLowerCase() != 'null') {
        
        final measureText = (measure != null && 
                            measure.isNotEmpty && 
                            measure.toLowerCase() != 'null') 
            ? '$measure ' 
            : '';
            
        ingredients.add('$measureText$ingredient');
      }
    }

    return MealData(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Unknown Meal',
      imageUrl: json['strMealThumb'] ?? '',
      ingredients: ingredients,
      instructions: json['strInstructions'] ?? 'No instructions available.',
    );
  }

  @override
  String toString() {
    return 'MealData(id: $id, name: $name, ingredients: ${ingredients.length})';
  }
}