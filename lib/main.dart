import 'package:flutter/material.dart';
import 'home_page.dart';
import 'prediction_page.dart';
import 'services/tensorflow_lite_service_safe.dart';
import 'services/local_nutrition_service.dart';
import 'services/food_analysis_isolate_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  String _initializationStatus = 'Memulai inisialisasi...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _initializationStatus = 'Menginisialisasi TensorFlow Lite...';
      });
      
      final tfInitialized = await TensorFlowLiteService.initialize();
      debugPrint('TensorFlow Lite diinisialisasi: $tfInitialized');
      
      setState(() {
        _initializationStatus = 'Menginisialisasi Local Nutrition Service...';
      });
      
      await LocalNutritionService.initialize();
      debugPrint('Service Nutrition lokal diinisialisasi: ${LocalNutritionService.isInitialized}');
      
      setState(() {
        _initializationStatus = 'Menginisialisasi Isolate Service...';
      });
      
      final isolateInitialized = await FoodAnalysisIsolateService.initialize();
      debugPrint('Isolate Service diinisialisasi: $isolateInitialized');
      
      setState(() {
        _isInitialized = true;
        _initializationStatus = 'Inisialisasi selesai!';
      });
      
    } catch (e) {
      debugPrint('Error saat inisialisasi services: $e');
      setState(() {
        _initializationStatus = 'Error inisialisasi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food ML',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isInitialized ? const HomePage() : _buildLoadingScreen(),
      routes: {
        '/prediction_page': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PredictionPage(
            imagePath: args['imagePath'] as String,
          );
        },
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // App title
              Text(
                'Food Recognizer',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              
              Text(
                'AI-Powered Food Recognition',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 50),
              
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              
              // Status text
              Text(
                _initializationStatus,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // Sub status
              Text(
                'Menyiapkan AI dan database nutrisi...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
