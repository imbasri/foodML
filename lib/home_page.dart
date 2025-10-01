import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Ensure state is properly initialized
    _selectedImage = null;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food ML'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome to Food ML',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an option to get started with food recognition:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_selectedImage != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _proceedToPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Proceed to Prediction',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],
            _buildActionButton(
              title: 'Pick from Gallery',
              icon: Icons.photo_library,
              color: Colors.blue,
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              title: 'Take Photo',
              icon: Icons.camera_alt,
              color: Colors.orange,
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              title: 'Quick Camera',
              icon: Icons.videocam,
              color: Colors.red,
              onPressed: _isLoading ? null : _openCameraFeed,
            ),
            const SizedBox(height: 40),
            if (_selectedImage == null)
              const Text(
                'No image selected yet. Please choose an option above.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      debugPrint('🚀 Starting image picking from: $source');

      // Pick image directly - let image_picker handle permissions
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        // User cancelled the picker
        debugPrint('❌ User cancelled image picking');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selection cancelled')),
          );
        }
        return;
      }

      debugPrint('✅ Image picked successfully: ${pickedFile.path}');

      // Convert to File first
      File imageFile = File(pickedFile.path);

      // Try cropping image (optional - gracefully handle failures)
      try {
        debugPrint('🖼️ Attempting to crop image...');
        final croppedFile = await _cropImage(pickedFile.path);
        
        if (croppedFile != null) {
          debugPrint('✅ Image cropped successfully: ${croppedFile.path}');
          imageFile = File(croppedFile.path);
        } else {
          debugPrint('ℹ️ Using original image (cropping skipped or failed)');
        }
      } catch (e) {
        debugPrint('⚠️ Cropping error (using original): $e');
        // Continue with original image
      }

      // Update state with final image
      setState(() {
        _selectedImage = imageFile;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected from ${source == ImageSource.camera ? 'camera' : 'gallery'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Image processing completed successfully');

    } on PlatformException catch (e) {
      debugPrint('❌ Platform error in image picking: ${e.code} - ${e.message}');
      
      String errorMessage;
      // Handle specific error codes from image_picker
      switch (e.code) {
        case 'camera_access_denied':
          errorMessage = 'Camera access denied.\n\nPlease:\n1. Go to Settings > Apps > Food ML > Permissions\n2. Enable Camera permission\n3. Try again';
          break;
        case 'photo_access_denied':
          errorMessage = 'Gallery access denied.\n\nPlease:\n1. Go to Settings > Apps > Food ML > Permissions\n2. Enable Photos/Storage permission\n3. Try again';
          break;
        case 'camera_access_restricted':
          errorMessage = 'Camera access is restricted on this device.\n\nPlease check device settings.';
          break;
        case 'photo_access_restricted':
          errorMessage = 'Gallery access is restricted on this device.\n\nPlease check device settings.';
          break;
        case 'no_available_camera':
          errorMessage = 'No camera available on this device.\n\nPlease try selecting from gallery instead.';
          break;
        default:
          errorMessage = 'Failed to access ${source == ImageSource.camera ? 'camera' : 'gallery'}.\n\nError: ${e.message ?? e.code}\n\nPlease check app permissions in Settings.';
      }
      
      _showErrorDialog(errorMessage);
    } catch (e) {
      debugPrint('❌ General error in image picking: $e');
      _showErrorDialog('Unexpected error: ${e.toString()}\n\nPlease try again or restart the app.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      debugPrint('🖼️ Starting image cropping: $imagePath');
      
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      
      if (croppedFile != null) {
        debugPrint('✅ Image cropped successfully: ${croppedFile.path}');
      } else {
        debugPrint('ℹ️ Image cropping cancelled by user');
      }
      
      return croppedFile;
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error in image cropping: ${e.code} - ${e.message}');
      
      // Handle specific cropper errors gracefully
      if (e.message?.contains('ActivityNotFoundException') == true ||
          e.message?.contains('UCropActivity') == true) {
        debugPrint('ℹ️ Image cropper activity not found, skipping crop');
      } else {
        debugPrint('ℹ️ Cropping failed, using original image');
      }
      
      // Always return null to use original image - no error dialog
      return null;
    } catch (e) {
      debugPrint('❌ General error in image cropping: $e');
      // Return null to use original image instead of showing error
      return null;
    }
  }

  Future<void> _openCameraFeed() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('📷 Opening camera for photo capture');
      
      // Directly use camera to take a photo
      // For live camera feed, you would need to implement camera plugin
      await _pickImage(ImageSource.camera);
      
    } catch (e) {
      debugPrint('❌ Error opening camera: $e');
      _showErrorDialog('Error opening camera: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _proceedToPrediction() async {
    if (_selectedImage == null) {
      _showErrorDialog('Please select an image first.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Navigate to prediction page
      if (mounted) {
        final result = await Navigator.pushNamed(
          context,
          '/prediction_page',
          arguments: {
            'imagePath': _selectedImage!.path,
          },
        );

        // Handle result if needed
        if (result != null) {
          // Process any result from prediction page
        }
      }
    } catch (e) {
      _showErrorDialog('Error navigating to prediction: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}