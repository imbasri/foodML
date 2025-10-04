import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/tensorflow_lite_service_safe.dart';
import 'services/local_nutrition_service.dart';
import 'services/food_analysis_isolate_service.dart';

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
  Map<String, dynamic>? _mealData;
  String? _errorMessage;
  String? _topPrediction;
  double? _score;
  String _loadingStatus = 'Memulai analisis...';
  final bool _useIsolate = true; // Flag untuk menggunakan Isolate atau tidak

  @override
  void initState() {
    super.initState();
    _initializeAndPredict();
  }

  /// Pastikan semua service sudah diinisialisasi sebelum prediksi
  Future<void> _initializeAndPredict() async {
    setState(() {
      _isLoadingPrediction = true;
      _loadingStatus = 'Memeriksa inisialisasi service...';
    });

    try {
      // Check dan tunggu TensorFlow Lite service
      if (!TensorFlowLiteService.isInitialized) {
        setState(() {
          _loadingStatus = 'Menginisialisasi TensorFlow Lite...';
        });
        final tfInitialized = await TensorFlowLiteService.initialize();
        if (!tfInitialized) {
          throw Exception('Gagal menginisialisasi TensorFlow Lite');
        }
      }

      // Check dan tunggu Local Nutrition service  
      if (!LocalNutritionService.isInitialized) {
        setState(() {
          _loadingStatus = 'Menginisialisasi Database Nutrisi...';
        });
        await LocalNutritionService.initialize();
        if (!LocalNutritionService.isInitialized) {
          throw Exception('Gagal menginisialisasi Database Nutrisi');
        }
      }

      // Check Isolate service untuk mobile
      if (!kIsWeb && !FoodAnalysisIsolateService.isInitialized) {
        setState(() {
          _loadingStatus = 'Menginisialisasi Background Processing...';
        });
        await FoodAnalysisIsolateService.initialize();
      }

      // Semua service siap, mulai prediksi
      await _performMLPrediction();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inisialisasi: $e';
        _isLoadingPrediction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'AI Food Analysis',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.blue.shade500,
              Colors.purple.shade300,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05, // 5% padding
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Tampilan gambar yang dipilih
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // AI Badge
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI Analysis',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu hasil prediksi AI
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Food Recognition Results',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isLoadingPrediction) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Analyzing Food...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _loadingStatus,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      kIsWeb ? 'Main Thread Processing (Web)' : 'Background Processing dengan Isolate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ] else if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Analysis Failed',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ] else ...[
                          // Food Recognition Results
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: Colors.green.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _topPrediction ?? "Unknown Food",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Identified by AI',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Confidence Score
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confidence: ${_score != null ? (_score! * 100).toStringAsFixed(1) : "--"}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Progress Bar
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _score ?? 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol untuk mendapatkan resep dan nutrisi
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingRecipe ? null : _getRecipe,
                    icon: _isLoadingRecipe
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.restaurant_menu, color: Colors.white),
                    label: Text(
                      _isLoadingRecipe ? 'Searching Recipes...' : 'Get Recipe & Nutrition Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Hasil informasi nutrisi dan resep
                if (_mealData != null) ...[
                  _buildEnhancedMealCard(_mealData!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performMLPrediction() async {
    // State sudah di-set di _initializeAndPredict, tidak perlu di-set lagi
    setState(() {
      _loadingStatus = 'Memulai analisis gambar...';
    });

    try {
      if (_useIsolate && FoodAnalysisIsolateService.isInitialized) {
        // Gunakan Isolate untuk background processing
        await _performAnalysisWithIsolate();
      } else {
        // Fallback ke method original jika Isolate tidak tersedia
        await _performAnalysisMainThread();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing image: $e';
      });
    } finally {
      setState(() {
        _isLoadingPrediction = false;
      });
    }
  }

  /// Analisis menggunakan Isolate untuk mencegah UI freezing
  Future<void> _performAnalysisWithIsolate() async {
    try {
      // Start loading animation stream
      final loadingStream = LoadingSimulationService.simulateAnalysisSteps();
      
      // Listen to loading steps dan update UI
      loadingStream.listen((status) {
        if (mounted) {
          setState(() {
            _loadingStatus = status;
          });
        }
      });

      // Jalankan analisis di background Isolate
      final result = await FoodAnalysisIsolateService.analyzeFood(widget.imagePath);
      
      if (result.error != null) {
        setState(() {
          _errorMessage = result.error;
        });
        return;
      }

      if (result.foodName != null) {
        setState(() {
          _topPrediction = result.foodName;
          _score = (result.confidence ?? 0.0) / 100.0;
          
          // Jika ada data nutrisi, langsung set
          if (result.nutrition != null) {
            _mealData = Map<String, dynamic>.from(result.nutrition!);
            if (result.recipes != null && result.recipes!.isNotEmpty) {
              _mealData!['recipe'] = result.recipes!.first;
              _mealData!['recipes'] = result.recipes;
            }
          }
          
          _loadingStatus = 'Analisis selesai!';
        });
      } else {
        setState(() {
          _errorMessage = 'Tidak dapat mengenali makanan dari gambar';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saat analisis dengan Isolate: $e';
      });
    }
  }

  /// Fallback method tanpa Isolate
  Future<void> _performAnalysisMainThread() async {
    setState(() {
      _loadingStatus = 'Menjalankan prediksi...';
    });

    final result = await TensorFlowLiteService.predictFood(widget.imagePath);
    
    if (result.isNotEmpty && result['food_name'] != null) {
      setState(() {
        _topPrediction = result['food_name'];
        _score = (result['confidence'] ?? 0.0) / 100.0;
        _loadingStatus = 'Prediksi selesai!';
      });
    } else {
      setState(() {
        _errorMessage = 'Tidak dapat mengenali makanan dari gambar';
      });
    }
  }

  Future<void> _getRecipe() async {
    if (_topPrediction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please detect food first')),
      );
      return;
    }

    setState(() {
      _isLoadingRecipe = true;
      _errorMessage = null;
      _mealData = null;
    });

    try {
      // Get both nutrition and recipe data
      final mealData = await LocalNutritionService.getNutritionInfo(_topPrediction!);
      final recipeData = await LocalNutritionService.getRecipes(_topPrediction!);
      
      // Combine nutrition and recipe data
      if (mealData != null) {
        final combinedData = Map<String, dynamic>.from(mealData);
        if (recipeData.isNotEmpty) {
          combinedData['recipe'] = recipeData.first; // Use the first recipe
          combinedData['recipes'] = recipeData; // Keep all recipes for potential use
        }
        
        setState(() {
          _mealData = combinedData;
        });
      } else {
        setState(() {
          _errorMessage = 'No nutrition data found for this food';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get nutrition and recipe info: $e';
      });
    } finally {
      setState(() {
        _isLoadingRecipe = false;
      });
    }
  }

  Widget _buildEnhancedMealCard(Map<String, dynamic> meal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.local_dining,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['food_name'] ?? 'Unknown Food',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Complete Nutrition & Recipe Guide',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tag informasi diet
            if (meal['dietaryInfo'] != null) ...[
              _buildDietaryTags(meal['dietaryInfo']),
              const SizedBox(height: 20),
            ],

            // Informasi nilai gizi utama
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nutrition Facts (per 100g)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid makronutrien utama yang responsif
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final cardWidth = (availableWidth - 12) / 2; // 2 cards with minimal spacing
                      
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildNutritionCard(
                                  'Calories',
                                  '${meal['calories'] ?? 0}',
                                  Icons.local_fire_department,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: cardWidth,
                                child: _buildNutritionCard(
                                  'Protein',
                                  '${meal['protein'] ?? 0}g',
                                  Icons.fitness_center,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildNutritionCard(
                                  'Carbs',
                                  '${meal['carbohydrates'] ?? 0}g',
                                  Icons.grain,
                                  Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: cardWidth,
                                child: _buildNutritionCard(
                                  'Fat',
                                  '${meal['fat'] ?? 0}g',
                                  Icons.opacity,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Informasi nutrisi tambahan
                  if (meal['fiber'] != null) _buildNutritionRow('Fiber', '${meal['fiber']}g', Icons.grass, Colors.green),
                  if (meal['sugar'] != null) _buildNutritionRow('Sugar', '${meal['sugar']}g', Icons.cake, Colors.pink),
                  if (meal['sodium'] != null) _buildNutritionRow('Sodium', '${meal['sodium']}mg', Icons.grain, Colors.red.shade300),
                ],
              ),
            ),

            // Micronutrients Section
            if (meal['nutrients'] != null) ...[
              const SizedBox(height: 20),
              _buildMicronutrientsSection(meal['nutrients']),
            ],

            // Health Benefits
            if (meal['benefits'] != null && (meal['benefits'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildBenefitsSection(meal['benefits']),
            ],

            // Bagian resep masakan
            if (meal['recipe'] != null) ...[
              const SizedBox(height: 20),
              _buildRecipeSection(meal['recipe']),
            ],

            // Preparation Tips
            if (meal['preparationTips'] != null && (meal['preparationTips'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildPreparationTipsSection(meal['preparationTips']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String label, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDietaryTags(Map<String, dynamic> dietaryInfo) {
    List<Widget> tags = [];
    
    if (dietaryInfo['isVegetarian'] == true) {
      tags.add(_buildDietaryTag('Vegetarian', Colors.green, Icons.eco));
    }
    if (dietaryInfo['isVegan'] == true) {
      tags.add(_buildDietaryTag('Vegan', Colors.green.shade700, Icons.local_florist));
    }
    if (dietaryInfo['isGlutenFree'] == true) {
      tags.add(_buildDietaryTag('Gluten Free', Colors.orange, Icons.no_food));
    }
    if (dietaryInfo['isDairyFree'] == true) {
      tags.add(_buildDietaryTag('Dairy Free', Colors.blue, Icons.block));
    }

    if (tags.isEmpty) return Container();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags,
    );
  }

  Widget _buildDietaryTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrientsSection(Map<String, dynamic> nutrients) {
    final micronutrients = [
      {'name': 'Vitamin A', 'value': nutrients['vitaminA'], 'icon': Icons.visibility, 'color': Colors.red},
      {'name': 'Vitamin C', 'value': nutrients['vitaminC'], 'icon': Icons.local_pharmacy, 'color': Colors.orange},
      {'name': 'Calcium', 'value': nutrients['calcium'], 'icon': Icons.fitness_center, 'color': Colors.grey},
      {'name': 'Iron', 'value': nutrients['iron'], 'icon': Icons.build, 'color': Colors.red.shade300},
      {'name': 'Potassium', 'value': nutrients['potassium'], 'icon': Icons.flash_on, 'color': Colors.purple},
      {'name': 'Magnesium', 'value': nutrients['magnesium'], 'icon': Icons.stars, 'color': Colors.green.shade300},
    ].where((nutrient) => nutrient['value'] != null).toList();

    if (micronutrients.isEmpty) return Container();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vitamins & Minerals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Use LayoutBuilder for better responsive design
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 2; // 2 items per row with spacing
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: micronutrients.map((nutrient) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: (nutrient['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (nutrient['color'] as Color).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            nutrient['icon'] as IconData,
                            size: 16,
                            color: nutrient['color'] as Color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    nutrient['name'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    nutrient['value'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: nutrient['color'] as Color,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(List benefits) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Health Benefits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      height: 1.4,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecipeSection(Map<String, dynamic> recipe) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recipe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informasi resep - layout responsif dengan spasi yang lebih baik
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final itemWidth = (availableWidth - 24) / 3; // 3 items with spacing
              
              return Row(
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildRecipeInfo('Prep', recipe['prepTime'] ?? '15 min', Icons.schedule),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: itemWidth,
                    child: _buildRecipeInfo('Cook', recipe['cookTime'] ?? '30 min', Icons.timer),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: itemWidth,
                    child: _buildRecipeInfo('Serves', '${recipe['servings'] ?? 4}', Icons.people),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Ingredients
          if (recipe['ingredients'] != null) ...[
            Text(
              'Ingredients:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (recipe['ingredients'] as List).map((ingredient) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            height: 1.3,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Instructions
          if (recipe['instructions'] != null) ...[
            Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (recipe['instructions'] as List).asMap().entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            height: 1.3,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.red.shade600,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationTipsSection(List preparationTips) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preparation Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...preparationTips.map((tip) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      height: 1.4,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}