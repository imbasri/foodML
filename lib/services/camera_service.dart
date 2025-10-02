import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;

  /// Initialize camera service
  static Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }
      
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('Camera service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return false;
    }
  }

  /// Get camera controller instance
  static CameraController? get controller => _controller;

  /// Check if camera is initialized
  static bool get isInitialized => _isInitialized && _controller != null;

  /// Capture image from camera stream
  static Future<String?> captureImage() async {
    if (!isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      debugPrint('Image captured: ${image.path}');
      return image.path;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Switch camera (front/back)
  static Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return false;
    }

    try {
      final currentCameraIndex = _cameras!.indexWhere(
        (camera) => camera == _controller!.description,
      );
      
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
      final newCamera = _cameras![newCameraIndex];

      await _controller!.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      debugPrint('Error switching camera: $e');
      return false;
    }
  }

  /// Toggle flash mode
  static Future<void> toggleFlash() async {
    if (!isInitialized) return;

    try {
      final currentFlashMode = _controller!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off 
          ? FlashMode.auto 
          : FlashMode.off;
      
      await _controller!.setFlashMode(newFlashMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Get current flash mode
  static FlashMode get flashMode => 
      _controller?.value.flashMode ?? FlashMode.off;

  /// Set zoom level for camera
  static Future<void> setZoomLevel(double zoomLevel) async {
    if (!isInitialized) return;

    try {
      // Clamp zoom level between min and max supported values (typically 1.0 to 8.0)
      final double clampedZoom = zoomLevel.clamp(1.0, 8.0);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
    }
  }

  /// Get maximum zoom level (default fallback)
  static Future<double> getMaxZoomLevel() async {
    if (!isInitialized) return 5.0;

    try {
      return await _controller!.getMaxZoomLevel();
    } catch (e) {
      debugPrint('Error getting max zoom level: $e');
      return 5.0;
    }
  }

  /// Dispose camera resources
  static Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  /// Get preview widget for camera stream
  static Widget getPreviewWidget() {
    if (!isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}