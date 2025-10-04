import 'dart:math';
import 'package:flutter/foundation.dart';

class LocalNutritionService {
  static bool _isInitialized = false;
  static Map<String, Map<String, dynamic>>? _nutritionDatabase;
  static Map<String, List<Map<String, dynamic>>>? _recipeDatabase;

  /// Initialize nutrition service with local database
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _nutritionDatabase = _buildNutritionDatabase();
      _recipeDatabase = _buildRecipeDatabase();
      _isInitialized = true;
      debugPrint('Local Nutrition Service initialized successfully');
      debugPrint('Nutrition database entries: ${_nutritionDatabase!.length}');
      debugPrint('Recipe database entries: ${_recipeDatabase!.length}');
    } catch (e) {
      debugPrint('Error initializing nutrition service: $e');
    }
  }

  /// Get nutrition information for a food item
  static Future<Map<String, dynamic>?> getNutritionInfo(String foodName) async {
    if (!_isInitialized) {
      debugPrint('Nutrition service belum diinisialisasi');
      return null;
    }

    try {
      // Coba berbagai pendekatan untuk menemukan makanan di database
      final searchKeys = <String>[
        _cleanFoodName(foodName),           // Clean original name
        _convertToDbKey(foodName),          // Convert formatted name to db key
        foodName.toLowerCase().replaceAll(' ', '_'), // Simple conversion
      ];
      
      // Remove duplicates
      final uniqueKeys = searchKeys.toSet().toList();
      
      // Try exact matches first
      for (final key in uniqueKeys) {
        if (_nutritionDatabase!.containsKey(key)) {
          debugPrint('Found exact match for: $key');
          return _nutritionDatabase![key];
        }
      }
      
      // Coba varian untuk setiap kunci
      for (final key in uniqueKeys) {
        final foodVariants = _getFoodVariants(key);
        for (final variant in foodVariants) {
          if (_nutritionDatabase!.containsKey(variant)) {
            debugPrint('Found variant match: $variant for key: $key');
            return _nutritionDatabase![variant];
          }
        }
      }
      
      // Coba pencocokan sebagian dengan kunci database
      for (final key in uniqueKeys) {
        for (final dbKey in _nutritionDatabase!.keys) {
          if (dbKey.contains(key) || key.contains(dbKey)) {
            debugPrint('Found partial match: $dbKey for key: $key');
            return _nutritionDatabase![dbKey];
          }
        }
      }
      
      // Generate data if not found
      debugPrint('No match found for: $foodName, generating new data');
      return _generateNutritionData(foodName);
    } catch (e) {
      debugPrint('Error mendapatkan informasi nutrisi: $e');
      return _generateNutritionData(foodName);
    }
  }

  /// Get recipes for a food item
  static Future<List<Map<String, dynamic>>> getRecipes(String foodName) async {
    if (!_isInitialized) {
      debugPrint('Nutrition service belum diinisialisasi');
      return [];
    }

    try {
      // Coba berbagai pendekatan untuk menemukan resep
      final searchKeys = <String>[
        _cleanFoodName(foodName),           // Clean original name
        _convertToDbKey(foodName),          // Convert formatted name to db key
        foodName.toLowerCase().replaceAll(' ', '_'), // Simple conversion
      ];
      
      // Remove duplicates
      final uniqueKeys = searchKeys.toSet().toList();
      
      // Try exact matches first
      for (final key in uniqueKeys) {
        if (_recipeDatabase!.containsKey(key)) {
          debugPrint('Found recipe exact match for: $key');
          return _recipeDatabase![key]!;
        }
      }
      
      // Try variants for each key
      for (final key in uniqueKeys) {
        final foodVariants = _getFoodVariants(key);
        for (final variant in foodVariants) {
          if (_recipeDatabase!.containsKey(variant)) {
            debugPrint('Found recipe variant match: $variant for key: $key');
            return _recipeDatabase![variant]!;
          }
        }
      }
      
      // Try partial matching with recipe database keys
      for (final key in uniqueKeys) {
        for (final dbKey in _recipeDatabase!.keys) {
          if (dbKey.contains(key) || key.contains(dbKey)) {
            debugPrint('Found recipe partial match: $dbKey for key: $key');
            return _recipeDatabase![dbKey]!;
          }
        }
      }
      
      // Jika tidak ada resep spesifik, cari berdasarkan kategori makanan
      debugPrint('No specific recipe found for: $foodName, looking for category matches');
      return await getRecipeRecommendations(foodName, []);
    } catch (e) {
      debugPrint('Error mendapatkan resep: $e');
      return [];
    }
  }

  /// Convert formatted food name back to database key format
  static String _convertToDbKey(String formattedName) {
    // Handle special cases first
    final specialCases = {
      'Margherita Pizza': 'margherita_pizza',
      'Pepperoni Pizza': 'pepperoni_pizza', 
      'Cheese Pizza': 'cheese_pizza',
      'Chicken Pizza': 'chicken_pizza',
      'Nasi Goreng': 'nasi_goreng',
      'Nasi Putih': 'nasi_putih',
      'Ayam Goreng': 'ayam_goreng',
      'Gado-gado': 'gado_gado',
      'Soto Ayam': 'soto_ayam',
      'Spaghetti Bolognese': 'spaghetti_bolognese',
      'Chicken Curry': 'chicken_curry',
      'Fried Rice': 'fried_rice',
      'Caesar Salad': 'caesar_salad',
    };

    if (specialCases.containsKey(formattedName)) {
      return specialCases[formattedName]!;
    }

    // Default conversion: lowercase and replace spaces with underscores
    return formattedName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  /// Clean food name for database lookup
  static String _cleanFoodName(String foodName) {
    return foodName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Get common variants and aliases for food names
  static List<String> _getFoodVariants(String cleanFoodName) {
    final variants = <String>[cleanFoodName];
    
    // Common variants mapping
    final variantMap = {
      'pizza': ['margherita_pizza', 'pepperoni_pizza', 'cheese_pizza', 'chicken_pizza'],
      'margherita_pizza': ['pizza', 'margherita', 'pizza_margherita'],
      'pepperoni_pizza': ['pizza', 'pepperoni', 'pizza_pepperoni'],
      'cheese_pizza': ['pizza', 'cheese', 'pizza_cheese'],
      'chicken_pizza': ['pizza', 'chicken', 'pizza_chicken'],
      'nasi_goreng': ['fried_rice', 'nasi', 'goreng'],
      'nasi_putih': ['rice', 'nasi', 'putih', 'white_rice'],
      'ayam_goreng': ['fried_chicken', 'ayam', 'chicken'],
      'gado_gado': ['gado', 'salad', 'indonesian_salad'],
      'soto_ayam': ['soto', 'chicken_soup', 'soup'],
      'spaghetti_bolognese': ['spaghetti', 'pasta', 'bolognese'],
      'chicken_curry': ['curry', 'chicken', 'kari_ayam'],
      'fried_rice': ['nasi_goreng', 'rice'],
      'caesar_salad': ['salad', 'caesar'],
    };
    
    if (variantMap.containsKey(cleanFoodName)) {
      variants.addAll(variantMap[cleanFoodName]!);
    }
    
    // Add partial matches
    for (final key in variantMap.keys) {
      if (key.contains(cleanFoodName) || cleanFoodName.contains(key)) {
        variants.addAll(variantMap[key]!);
        variants.add(key);
      }
    }
    
    return variants.toSet().toList();
  }

  /// Format food name consistently - same as TensorFlow service
  static String _formatFoodName(String rawName) {
    // Handle special cases first
    final specialCases = {
      'margherita_pizza': 'Margherita Pizza',
      'pepperoni_pizza': 'Pepperoni Pizza', 
      'cheese_pizza': 'Cheese Pizza',
      'chicken_pizza': 'Chicken Pizza',
      'nasi_goreng': 'Nasi Goreng',
      'nasi_putih': 'Nasi Putih',
      'ayam_goreng': 'Ayam Goreng',
      'gado_gado': 'Gado-gado',
      'soto_ayam': 'Soto Ayam',
      'spaghetti_bolognese': 'Spaghetti Bolognese',
      'chicken_curry': 'Chicken Curry',
      'fried_rice': 'Fried Rice',
      'caesar_salad': 'Caesar Salad',
    };

    final cleanName = rawName.toLowerCase().trim();
    if (specialCases.containsKey(cleanName)) {
      return specialCases[cleanName]!;
    }

    // Default formatting: replace underscore with space and capitalize each word
    final words = rawName.replaceAll('_', ' ').split(' ');
    final formattedWords = <String>[];
    
    for (final word in words) {
      if (word.isNotEmpty) {
        // Capitalize first letter, lowercase the rest
        final capitalizedWord = word[0].toUpperCase() + word.substring(1).toLowerCase();
        formattedWords.add(capitalizedWord);
      }
    }
    
    return formattedWords.join(' ');
  }

  /// Generate nutrition data when not found in database
  static Map<String, dynamic> _generateNutritionData(String foodName) {
    final random = Random();
    final baseCalories = 200 + random.nextInt(200);
    final baseProtein = 5.0 + (random.nextDouble() * 15.0);
    final baseCarbs = 15.0 + (random.nextDouble() * 30.0);
    final baseFat = 5.0 + (random.nextDouble() * 15.0);
    
    // Format the food name consistently
    final formattedFoodName = _formatFoodName(foodName);
    
    return {
      'food_name': formattedFoodName,
      'calories': baseCalories,
      'protein': double.parse(baseProtein.toStringAsFixed(1)),
      'carbohydrates': double.parse(baseCarbs.toStringAsFixed(1)),
      'fat': double.parse(baseFat.toStringAsFixed(1)),
      'fiber': double.parse((random.nextDouble() * 5.0).toStringAsFixed(1)),
      'sugar': double.parse((random.nextDouble() * 10.0).toStringAsFixed(1)),
      'sodium': 300 + random.nextInt(500),
      'description': 'Estimasi nutrisi untuk $formattedFoodName',
      'source': 'Generated',
    };
  }

  /// Build comprehensive nutrition database
  static Map<String, Map<String, dynamic>> _buildNutritionDatabase() {
    return {
      // Pizza variants
      'margherita_pizza': {
        'food_name': 'Margherita Pizza',
        'calories': 266,
        'protein': 11.0,
        'carbohydrates': 33.0,
        'fat': 10.1,
        'fiber': 2.3,
        'sugar': 3.8,
        'sodium': 598,
        'description': 'Pizza klasik dengan tomat, mozzarella, dan basil',
        'source': 'USDA Database',
      },
      'pepperoni_pizza': {
        'food_name': 'Pepperoni Pizza',
        'calories': 298,
        'protein': 13.2,
        'carbohydrates': 35.7,
        'fat': 11.8,
        'fiber': 2.5,
        'sugar': 4.2,
        'sodium': 720,
        'description': 'Pizza dengan topping pepperoni yang gurih',
        'source': 'USDA Database',
      },
      'cheese_pizza': {
        'food_name': 'Cheese Pizza',
        'calories': 285,
        'protein': 12.1,
        'carbohydrates': 35.8,
        'fat': 10.4,
        'fiber': 2.5,
        'sugar': 3.8,
        'sodium': 640,
        'description': 'Pizza keju klasik dengan mozzarella melimpah',
        'source': 'USDA Database',
      },
      'chicken_pizza': {
        'food_name': 'Chicken Pizza',
        'calories': 309,
        'protein': 15.8,
        'carbohydrates': 33.2,
        'fat': 12.1,
        'fiber': 2.4,
        'sugar': 3.5,
        'sodium': 678,
        'description': 'Pizza dengan topping ayam yang lezat',
        'source': 'USDA Database',
      },
      // Indonesian foods
      'nasi_goreng': {
        'food_name': 'Nasi Goreng',
        'calories': 250,
        'protein': 8.5,
        'carbohydrates': 42.0,
        'fat': 6.2,
        'fiber': 1.8,
        'sugar': 2.5,
        'sodium': 580,
        'description': 'Nasi goreng Indonesia dengan bumbu kecap dan rempah',
        'source': 'Indonesia Food Database',
      },
      'nasi_putih': {
        'food_name': 'Nasi Putih',
        'calories': 130,
        'protein': 2.7,
        'carbohydrates': 28.0,
        'fat': 0.3,
        'fiber': 0.4,
        'sugar': 0.1,
        'sodium': 1,
        'description': 'Nasi putih sebagai makanan pokok',
        'source': 'Indonesia Food Database',
      },
      'ayam_goreng': {
        'food_name': 'Ayam Goreng',
        'calories': 320,
        'protein': 25.8,
        'carbohydrates': 8.2,
        'fat': 20.5,
        'fiber': 0.5,
        'sugar': 1.2,
        'sodium': 456,
        'description': 'Ayam goreng dengan bumbu rempah Indonesia',
        'source': 'Indonesia Food Database',
      },
      'gado_gado': {
        'food_name': 'Gado-gado',
        'calories': 180,
        'protein': 8.5,
        'carbohydrates': 15.2,
        'fat': 9.8,
        'fiber': 5.2,
        'sugar': 8.5,
        'sodium': 320,
        'description': 'Salad sayuran Indonesia dengan bumbu kacang',
        'source': 'Indonesia Food Database',
      },
      'soto_ayam': {
        'food_name': 'Soto Ayam',
        'calories': 165,
        'protein': 12.5,
        'carbohydrates': 18.2,
        'fat': 4.8,
        'fiber': 2.1,
        'sugar': 3.2,
        'sodium': 890,
        'description': 'Sup ayam kuning dengan rempah khas Indonesia',
        'source': 'Indonesia Food Database',
      },
      // Western foods
      'spaghetti_bolognese': {
        'food_name': 'Spaghetti Bolognese',
        'calories': 220,
        'protein': 11.2,
        'carbohydrates': 31.5,
        'fat': 6.8,
        'fiber': 2.8,
        'sugar': 5.2,
        'sodium': 456,
        'description': 'Pasta spaghetti dengan saus daging bolognese',
        'source': 'International Database',
      },
      'chicken_curry': {
        'food_name': 'Chicken Curry',
        'calories': 195,
        'protein': 18.5,
        'carbohydrates': 8.2,
        'fat': 10.8,
        'fiber': 2.1,
        'sugar': 4.8,
        'sodium': 650,
        'description': 'Kari ayam dengan rempah-rempah',
        'source': 'International Database',
      },
      'fried_rice': {
        'food_name': 'Fried Rice',
        'calories': 228,
        'protein': 7.2,
        'carbohydrates': 39.8,
        'fat': 5.2,
        'fiber': 1.5,
        'sugar': 2.1,
        'sodium': 520,
        'description': 'Nasi goreng ala western dengan sayuran',
        'source': 'International Database',
      },
      'caesar_salad': {
        'food_name': 'Caesar Salad',
        'calories': 158,
        'protein': 8.9,
        'carbohydrates': 8.5,
        'fat': 11.2,
        'fiber': 3.2,
        'sugar': 3.8,
        'sodium': 456,
        'description': 'Salad romaine dengan dressing caesar',
        'source': 'International Database',
      },
    };
  }

  /// Build comprehensive recipe database
  static Map<String, List<Map<String, dynamic>>> _buildRecipeDatabase() {
    return {
      'margherita_pizza': [
        {
          'title': 'Pizza Margherita Klasik',
          'description': 'Pizza Italia autentik dengan tomat, mozzarella, dan basil segar',
          'prep_time': '20 menit',
          'cook_time': '12 menit',
          'difficulty': 'Sedang',
          'ingredients': [
            '250g tepung terigu protein tinggi',
            '150ml air hangat',
            '1 sdt ragi instant',
            '1 sdt garam',
            '2 sdm olive oil',
            '200g saus tomat',
            '200g mozzarella cheese',
            'Daun basil segar',
            'Garam dan merica'
          ],
          'instructions': [
            'Campurkan tepung, ragi, dan garam dalam mangkuk',
            'Tambahkan air hangat dan olive oil, aduk hingga menjadi adonan',
            'Uleni adonan selama 8-10 menit hingga halus dan elastis',
            'Diamkan adonan 1 jam hingga mengembang 2x lipat',
            'Bentuk adonan menjadi bulat pipih',
            'Oleskan saus tomat tipis-tipis',
            'Taburkan mozzarella dan beri daun basil',
            'Panggang dalam oven 220°C selama 10-12 menit'
          ],
          'nutrition_tips': 'Pizza homemade lebih sehat karena bisa mengontrol jumlah garam dan lemak',
          'source': 'Italian Recipe Collection'
        }
      ],
      'nasi_goreng': [
        {
          'title': 'Nasi Goreng Spesial',
          'description': 'Nasi goreng dengan telur, ayam, dan sayuran',
          'prep_time': '15 menit',
          'cook_time': '20 menit',
          'difficulty': 'Mudah',
          'ingredients': [
            '3 piring nasi putih',
            '2 butir telur',
            '200g ayam fillet, potong dadu',
            '3 siung bawang putih, cincang',
            '2 sdm kecap manis',
            '1 sdt garam',
            'Minyak untuk menumis'
          ],
          'instructions': [
            'Panaskan minyak dalam wajan',
            'Tumis bawang putih hingga harum',
            'Masukkan ayam, masak hingga matang',
            'Kocok telur, buat orak-arik',
            'Masukkan nasi, aduk rata',
            'Tambahkan kecap manis dan garam',
            'Aduk hingga bumbu merata dan sajikan'
          ],
          'nutrition_tips': 'Tambahkan sayuran untuk meningkatkan kandungan vitamin',
          'source': 'Indonesian Traditional Recipe'
        }
      ],
      'gado_gado': [
        {
          'title': 'Gado-gado Jakarta',
          'description': 'Salad sayuran tradisional dengan bumbu kacang yang kaya',
          'prep_time': '30 menit',
          'cook_time': '15 menit',
          'difficulty': 'Mudah',
          'ingredients': [
            '100g tauge',
            '100g kacang panjang',
            '2 buah kentang rebus',
            '2 butir telur rebus',
            '100g tahu goreng',
            '100g kacang tanah sangrai',
            '3 buah cabai merah',
            '2 siung bawang putih',
            '1 sdm gula merah',
            '1 sdt terasi',
            'Garam secukupnya'
          ],
          'instructions': [
            'Rebus sayuran hingga matang tapi masih renyah',
            'Goreng tahu hingga keemasan',
            'Haluskan kacang tanah, cabai, bawang putih, dan terasi',
            'Tambahkan gula merah dan garam',
            'Siram bumbu kacang ke atas sayuran',
            'Sajikan dengan kerupuk'
          ],
          'nutrition_tips': 'Kaya protein nabati dan vitamin dari sayuran segar',
          'source': 'Jakarta Street Food'
        }
      ],
      'spaghetti_bolognese': [
        {
          'title': 'Spaghetti Bolognese Tradisional',
          'description': 'Pasta dengan saus daging klasik dari Bologna, Italia',
          'prep_time': '15 menit',
          'cook_time': '45 menit',
          'difficulty': 'Sedang',
          'ingredients': [
            '400g spaghetti',
            '300g daging sapi giling',
            '1 buah wortel, potong dadu',
            '1 batang seledri, potong dadu',
            '1 buah bawang bombay, cincang',
            '400g tomat kalengan',
            '100ml red wine (opsional)',
            '2 sdm olive oil',
            'Garam dan merica',
            'Keju parmesan parut'
          ],
          'instructions': [
            'Panaskan olive oil, tumis bawang bombay hingga harum',
            'Masukkan wortel dan seledri, tumis 5 menit',
            'Tambahkan daging giling, masak hingga berubah warna',
            'Tuang red wine, masak hingga alkohol menguap',
            'Masukkan tomat, bumbui dengan garam dan merica',
            'Masak dengan api kecil selama 30 menit',
            'Rebus spaghetti al dente',
            'Sajikan pasta dengan saus dan keju parmesan'
          ],
          'nutrition_tips': 'Sumber protein tinggi dan karbohidrat kompleks',
          'source': 'Traditional Italian Recipe'
        }
      ],
      'chicken_curry': [
        {
          'title': 'Kari Ayam Sederhana',
          'description': 'Kari ayam dengan bumbu rempah yang harum dan kaya rasa',
          'prep_time': '20 menit',
          'cook_time': '35 menit',
          'difficulty': 'Sedang',
          'ingredients': [
            '500g ayam, potong sedang',
            '200ml santan kental',
            '2 sdm bumbu kari',
            '1 buah bawang bombay, iris',
            '3 siung bawang putih, cincang',
            '1 ruas jahe, parut',
            '2 buah kentang, potong dadu',
            'Garam dan gula secukupnya',
            'Minyak untuk menumis'
          ],
          'instructions': [
            'Panaskan minyak, tumis bawang bombay hingga layu',
            'Masukkan bawang putih dan jahe, tumis hingga harum',
            'Tambahkan bumbu kari, tumis 2 menit',
            'Masukkan ayam, aduk hingga bumbu merata',
            'Tuang santan, masak hingga mendidih',
            'Tambahkan kentang, masak hingga empuk',
            'Bumbui dengan garam dan gula',
            'Sajikan dengan nasi putih atau roti'
          ],
          'nutrition_tips': 'Tinggi protein dan antioksidan dari rempah-rempah',
          'source': 'Asian Curry Collection'
        }
      ]
    };
  }

  static bool get isInitialized => _isInitialized;

  /// Get recipe recommendations berdasarkan kategori makanan dari LiteRT
  static Future<List<Map<String, dynamic>>> getRecipeRecommendations(
    String detectedFood, 
    List<Map<String, dynamic>> predictions
  ) async {
    if (!_isInitialized) {
      debugPrint('Nutrition service belum diinisialisasi');
      return [];
    }

    try {
      final cleanName = _cleanFoodName(detectedFood);
      
      // Klasifikasi berdasarkan jenis makanan
      if (_isRiceBasedFood(cleanName)) {
        return _getRiceBasedRecommendations();
      } else if (_isChickenBasedFood(cleanName)) {
        return _getChickenBasedRecommendations();
      } else if (_isVegetableBasedFood(cleanName)) {
        return _getVegetableBasedRecommendations();
      } else if (_isPizzaBasedFood(cleanName)) {
        return _getPizzaBasedRecommendations();
      } else if (_isPastaBasedFood(cleanName)) {
        return _getPastaBasedRecommendations();
      }
      
      return _getGeneralRecommendations();
    } catch (e) {
      debugPrint('Error mendapatkan rekomendasi resep: $e');
      return _getGeneralRecommendations();
    }
  }

  /// Check if food is rice-based
  static bool _isRiceBasedFood(String cleanName) {
    final riceKeywords = ['nasi', 'rice', 'fried_rice', 'nasi_goreng'];
    return riceKeywords.any((keyword) => cleanName.contains(keyword));
  }

  /// Check if food is chicken-based
  static bool _isChickenBasedFood(String cleanName) {
    final chickenKeywords = ['ayam', 'chicken', 'soto_ayam', 'chicken_curry'];
    return chickenKeywords.any((keyword) => cleanName.contains(keyword));
  }

  /// Check if food is vegetable-based
  static bool _isVegetableBasedFood(String cleanName) {
    final vegetableKeywords = ['gado', 'salad', 'sayur', 'vegetable'];
    return vegetableKeywords.any((keyword) => cleanName.contains(keyword));
  }

  /// Check if food is pizza-based
  static bool _isPizzaBasedFood(String cleanName) {
    final pizzaKeywords = ['pizza', 'margherita', 'pepperoni'];
    return pizzaKeywords.any((keyword) => cleanName.contains(keyword));
  }

  /// Check if food is pasta-based
  static bool _isPastaBasedFood(String cleanName) {
    final pastaKeywords = ['spaghetti', 'pasta', 'bolognese'];
    return pastaKeywords.any((keyword) => cleanName.contains(keyword));
  }

  /// Get pizza-based recommendations
  static List<Map<String, dynamic>> _getPizzaBasedRecommendations() {
    return [
      {
        'title': 'Pizza Sayuran Sehat',
        'description': 'Pizza dengan topping sayuran segar dan keju rendah lemak',
        'prep_time': '25 menit',
        'cook_time': '15 menit',
        'difficulty': 'Mudah',
        'category': 'Pizza Dishes',
        'nutrition_tips': 'Gunakan whole wheat untuk adonan yang lebih sehat',
        'source': 'Healthy Pizza Collection'
      }
    ];
  }

  /// Get pasta-based recommendations
  static List<Map<String, dynamic>> _getPastaBasedRecommendations() {
    return [
      {
        'title': 'Pasta Aglio Olio Sehat',
        'description': 'Pasta sederhana dengan minyak zaitun, bawang putih, dan sayuran',
        'prep_time': '10 menit',
        'cook_time': '15 menit',
        'difficulty': 'Mudah',
        'category': 'Pasta Dishes',
        'nutrition_tips': 'Tambahkan sayuran hijau untuk nutrisi lengkap',
        'source': 'Healthy Pasta Collection'
      }
    ];
  }

  /// General recommendations when no specific category matches
  static List<Map<String, dynamic>> _getGeneralRecommendations() {
    return [
      {
        'title': 'Makanan Seimbang',
        'description': 'Kombinasi protein, karbohidrat, dan sayuran untuk nutrisi optimal',
        'prep_time': '20 menit',
        'cook_time': '25 menit',
        'difficulty': 'Mudah',
        'category': 'Balanced Meals',
        'nutrition_tips': 'Pastikan setiap makanan mengandung protein, karbohidrat, dan sayuran',
        'source': 'General Nutrition Guide'
      }
    ];
  }

  /// Rekomendasi untuk kategori nasi
  static List<Map<String, dynamic>> _getRiceBasedRecommendations() {
    return [
      {
        'title': 'Nasi Kuning Spesial',
        'description': 'Nasi kuning dengan lauk lengkap',
        'prep_time': '20 menit',
        'cook_time': '40 menit',
        'difficulty': 'Sedang',
        'category': 'Rice Dishes',
        'nutrition_tips': 'Kaya karbohidrat, tambahkan protein dan sayur',
        'source': 'Category Recommendation'
      }
    ];
  }

  /// Rekomendasi untuk kategori ayam
  static List<Map<String, dynamic>> _getChickenBasedRecommendations() {
    return [
      {
        'title': 'Ayam Bumbu Bali',
        'description': 'Ayam dengan bumbu khas Bali yang kaya rempah',
        'prep_time': '25 menit',
        'cook_time': '35 menit',
        'difficulty': 'Sedang',
        'category': 'Chicken Dishes',
        'nutrition_tips': 'Tinggi protein, baik untuk pembentukan otot',
        'source': 'Category Recommendation'
      }
    ];
  }

  /// Rekomendasi untuk kategori sayuran
  static List<Map<String, dynamic>> _getVegetableBasedRecommendations() {
    return [
      {
        'title': 'Tumis Sayuran Campur',
        'description': 'Sayuran segar tumis dengan bumbu sederhana',
        'prep_time': '15 menit',
        'cook_time': '10 menit',
        'difficulty': 'Mudah',
        'category': 'Vegetable Dishes',
        'nutrition_tips': 'Kaya vitamin dan mineral, rendah kalori',
        'source': 'Category Recommendation'
      }
    ];
  }
}