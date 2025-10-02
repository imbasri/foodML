import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PredictionPage extends StatefulWidget {
  final String imagePath;
  final String topPrediction;
  final double score;

  const PredictionPage({
    super.key,
    required this.imagePath,
    required this.topPrediction,
    required this.score,
  });

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  bool _isLoadingRecipe = false;
  MealData? _mealData;
  String? _errorMessage;

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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Prediction Results Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.label, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Food Item: ${widget.topPrediction}',
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
                          'Confidence: ${(widget.score * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: widget.score,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.score > 0.7 
                            ? Colors.green 
                            : widget.score > 0.4 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Get Recipe Button
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
                _isLoadingRecipe ? 'Searching Recipes...' : 'Get Recipe',
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

            // Recipe Results
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
                          fontWeight: FontWeight.w500,
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
            // Meal Name
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),

            // Meal Image
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

            // Ingredients Section
            const Text(
              'Ingredients',
              style: TextStyle(
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
                      const Icon(
                        Icons.circle,
                        size: 8,
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

            // Instructions Section
            const Text(
              'Cooking Instructions',
              style: TextStyle(
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

  Future<void> _getRecipe() async {
    setState(() {
      _isLoadingRecipe = true;
      _errorMessage = null;
      _mealData = null;
    });

    try {
      final mealData = await _searchMealByName(widget.topPrediction);
      
      if (mealData != null) {
        setState(() {
          _mealData = mealData;
        });
      } else {
        setState(() {
          _errorMessage = 'No recipes found for "${widget.topPrediction}".\n\n'
              'This could be because:\n'
              '• The food item is not in TheMealDB database\n'
              '• The prediction label doesn\'t match recipe names\n'
              '• Try searching for a more general food category';
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