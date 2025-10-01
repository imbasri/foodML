import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Prediction result containing label and confidence score
class PredictionResult {
  final String label;
  final double confidence;
  final int index;

  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.index,
  });

  @override
  String toString() => 'PredictionResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(2)}%)';
}

/// Parameters for isolate inference
class InferenceParams {
  final String imagePath;
  final String? modelPath;
  final List<String>? labels;
  final int inputSize;
  final double mean;
  final double std;

  const InferenceParams({
    required this.imagePath,
    this.modelPath,
    this.labels,
    this.inputSize = 224,
    this.mean = 127.5,
    this.std = 127.5,
  });
}

/// TensorFlow Lite service for image classification
class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  // TODO: Adapt these values based on your specific model requirements
  // Common values:
  // - MobileNet: mean=127.5, std=127.5 (input range: -1 to 1)
  // - Inception: mean=0.5, std=0.5 (input range: 0 to 1)
  // - EfficientNet: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225] (ImageNet normalization)
  static const double _defaultMean = 127.5;
  static const double _defaultStd = 127.5;
  static const int _defaultInputSize = 224;

  /// Initialize the TFLite service with model and labels
  /// 
  /// [modelPath] - Path to the .tflite model file (if null, loads from assets/models/model.tflite)
  /// [labelsPath] - Path to the labels file (if null, loads from assets/models/labels.txt)
  Future<void> initialize({
    String? modelPath,
    String? labelsPath,
  }) async {
    try {
      // Load model
      if (modelPath != null && File(modelPath).existsSync()) {
        _interpreter = await Interpreter.fromFile(File(modelPath));
      } else {
        // TODO: Replace 'assets/models/model.tflite' with your actual model path
        _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      }

      // Load labels
      if (labelsPath != null && File(labelsPath).existsSync()) {
        final labelsContent = await File(labelsPath).readAsString();
        _labels = labelsContent.split('\n').where((line) => line.isNotEmpty).toList();
      } else {
        // TODO: Replace 'assets/models/labels.txt' with your actual labels file path
        try {
          final labelsContent = await rootBundle.loadString('assets/models/labels.txt');
          _labels = labelsContent.split('\n').where((line) => line.isNotEmpty).toList();
        } catch (e) {
          debugPrint('Warning: Could not load labels file. Using index-based labels.');
          _labels = null;
        }
      }

      debugPrint('TFLite model loaded successfully');
      debugPrint('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      debugPrint('Labels count: ${_labels?.length ?? "No labels loaded"}');
    } catch (e) {
      debugPrint('Error initializing TFLite: $e');
      rethrow;
    }
  }

  /// Preprocess image file into normalized tensor
  /// 
  /// [imagePath] - Path to the image file
  /// [inputSize] - Target size for the model input (default: 224)
  /// [mean] - Mean for normalization (default: 127.5)
  /// [std] - Standard deviation for normalization (default: 127.5)
  Future<Float32List> _preprocessImage(
    String imagePath, {
    int inputSize = _defaultInputSize,
    double mean = _defaultMean,
    double std = _defaultStd,
  }) async {
    try {
      // Read and decode image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image: $imagePath');
      }

      // Resize image to model input size
      image = img.copyResize(image, width: inputSize, height: inputSize);

      // Convert to Float32List with normalization
      final input = Float32List(inputSize * inputSize * 3);
      int pixelIndex = 0;

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = image.getPixel(x, y);
          
          // Extract RGB values and normalize
          // TODO: Adapt normalization based on your model requirements
          // Option 1: Standard normalization (range: -1 to 1)
          input[pixelIndex++] = (pixel.r - mean) / std;
          input[pixelIndex++] = (pixel.g - mean) / std;
          input[pixelIndex++] = (pixel.b - mean) / std;
          
          // Option 2: Simple normalization (range: 0 to 1)
          // input[pixelIndex++] = pixel.r / 255.0;
          // input[pixelIndex++] = pixel.g / 255.0;
          // input[pixelIndex++] = pixel.b / 255.0;
          
          // Option 3: ImageNet normalization (uncomment if using ImageNet pretrained models)
          // input[pixelIndex++] = (pixel.r / 255.0 - 0.485) / 0.229;
          // input[pixelIndex++] = (pixel.g / 255.0 - 0.456) / 0.224;
          // input[pixelIndex++] = (pixel.b / 255.0 - 0.406) / 0.225;
        }
      }

      return input;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      rethrow;
    }
  }

  /// Run inference on preprocessed image data
  /// 
  /// [imagePath] - Path to the image file
  /// [inputSize] - Target size for the model input
  /// [mean] - Mean for normalization
  /// [std] - Standard deviation for normalization
  /// Returns top 3 predictions sorted by confidence (descending)
  Future<List<PredictionResult>> predict(
    String imagePath, {
    int inputSize = _defaultInputSize,
    double mean = _defaultMean,
    double std = _defaultStd,
  }) async {
    if (_interpreter == null) {
      throw Exception('TFLite model not initialized. Call initialize() first.');
    }

    try {
      // Preprocess image
      final input = await _preprocessImage(
        imagePath,
        inputSize: inputSize,
        mean: mean,
        std: std,
      );

      // Prepare input tensor
      final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

      // Prepare output tensor
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      final output = List.filled(outputSize, 0.0).reshape(outputShape);

      // Run inference
      _interpreter!.run(inputTensor, output);

      // Process results
      final predictions = <PredictionResult>[];
      final scores = output[0] as List<double>;

      for (int i = 0; i < scores.length; i++) {
        final label = _labels != null && i < _labels!.length 
            ? _labels![i] 
            : 'Class $i';
            
        predictions.add(PredictionResult(
          label: label,
          confidence: scores[i],
          index: i,
        ));
      }

      // Sort by confidence and return top 3
      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      return predictions.take(3).toList();
    } catch (e) {
      debugPrint('Error during prediction: $e');
      rethrow;
    }
  }

  /// Run inference in an isolate to avoid blocking the UI thread
  /// 
  /// [imagePath] - Path to the image file
  /// [modelPath] - Optional custom model path
  /// [labels] - Optional custom labels list
  /// [inputSize] - Target size for the model input
  /// [mean] - Mean for normalization
  /// [std] - Standard deviation for normalization
  /// Returns top 3 predictions sorted by confidence (descending)
  static Future<List<PredictionResult>> inferInIsolate(
    String imagePath, {
    String? modelPath,
    List<String>? labels,
    int inputSize = _defaultInputSize,
    double mean = _defaultMean,
    double std = _defaultStd,
  }) async {
    final params = InferenceParams(
      imagePath: imagePath,
      modelPath: modelPath,
      labels: labels,
      inputSize: inputSize,
      mean: mean,
      std: std,
    );

    return await compute(_isolateInference, params);
  }

  /// Isolate function for running inference
  static Future<List<PredictionResult>> _isolateInference(InferenceParams params) async {
    final service = TFLiteService();
    
    try {
      // Initialize in isolate
      await service.initialize(modelPath: params.modelPath);
      
      // Override labels if provided
      if (params.labels != null) {
        service._labels = params.labels;
      }
      
      // Run prediction
      final results = await service.predict(
        params.imagePath,
        inputSize: params.inputSize,
        mean: params.mean,
        std: params.std,
      );
      
      return results;
    } finally {
      service.dispose();
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _interpreter != null;

  /// Get model input shape
  List<int>? get inputShape => _interpreter?.getInputTensor(0).shape;

  /// Get model output shape
  List<int>? get outputShape => _interpreter?.getOutputTensor(0).shape;

  /// Get loaded labels
  List<String>? get labels => _labels;

  /// Dispose of resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}

/// Extension to help with tensor reshaping
extension on List<double> {
  List<List<List<List<double>>>> reshape(List<int> shape) {
    if (shape.length != 4) {
      throw ArgumentError('Expected 4D shape for image tensor');
    }
    
    final result = <List<List<List<double>>>>[];
    int index = 0;
    
    for (int i = 0; i < shape[0]; i++) {
      final batch = <List<List<double>>>[];
      for (int j = 0; j < shape[1]; j++) {
        final row = <List<double>>[];
        for (int k = 0; k < shape[2]; k++) {
          final pixel = <double>[];
          for (int l = 0; l < shape[3]; l++) {
            pixel.add(this[index++]);
          }
          row.add(pixel);
        }
        batch.add(row);
      }
      result.add(batch);
    }
    
    return result;
  }
}

extension on Float32List {
  List<List<List<List<double>>>> reshape(List<int> shape) {
    if (shape.length != 4) {
      throw ArgumentError('Expected 4D shape for image tensor');
    }
    
    final result = <List<List<List<double>>>>[];
    int index = 0;
    
    for (int i = 0; i < shape[0]; i++) {
      final batch = <List<List<double>>>[];
      for (int j = 0; j < shape[1]; j++) {
        final row = <List<double>>[];
        for (int k = 0; k < shape[2]; k++) {
          final pixel = <double>[];
          for (int l = 0; l < shape[3]; l++) {
            pixel.add(this[index++].toDouble());
          }
          row.add(pixel);
        }
        batch.add(row);
      }
      result.add(batch);
    }
    
    return result;
  }
}