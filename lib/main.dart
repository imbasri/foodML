import 'package:flutter/material.dart';
import 'home_page.dart';
import 'prediction_page.dart';
import 'services/tensorflow_lite_service.dart';
import 'services/gemini_nutrition_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeServices();
  runApp(const MyApp());
}

void _initializeServices() async {
  try {
    final tfInitialized = await TensorFlowLiteService.initialize();
    debugPrint('TensorFlow Lite diinisialisasi: $tfInitialized');
    
    final geminiInitialized = await GeminiNutritionService.initialize();
    debugPrint('Service Gemini diinisialisasi: $geminiInitialized');
  } catch (e) {
    debugPrint('Error saat inisialisasi services: $e');
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
