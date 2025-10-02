import 'package:flutter/material.dart';
import 'home_page.dart';
import 'prediction_page.dart';
import 'services/tensorflow_lite_service.dart';
import 'services/gemini_nutrition_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services in background
  _initializeServices();
  
  runApp(const MyApp());
}

/// Initialize all AI services in background
void _initializeServices() async {
  try {
    // Initialize TensorFlow Lite service
    final tfInitialized = await TensorFlowLiteService.initialize();
    debugPrint('TensorFlow Lite initialized: $tfInitialized');
    
    // Initialize Gemini service
    final geminiInitialized = await GeminiNutritionService.initialize();
    debugPrint('Gemini service initialized: $geminiInitialized');
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food ML',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
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
}
