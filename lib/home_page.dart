import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'services/camera_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _cameraInitialized = false;
  double _currentZoom = 1.0;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    } else if (state == AppLifecycleState.paused) {
      CameraService.dispose();
      setState(() {
        _cameraInitialized = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    final success = await CameraService.initialize();
    setState(() {
      _cameraInitialized = success;
      _isLoading = false;
    });

    if (!success) {
      _showErrorDialog('Failed to initialize camera. Please check your device camera.');
    }
  }

  Future<void> _captureImage() async {
    if (!_cameraInitialized) {
      _showErrorDialog('Camera not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imagePath = await CameraService.captureImage();
      if (imagePath != null) {
        _navigateToPrediction(imagePath);
      } else {
        _showErrorDialog('Failed to capture image');
      }
    } catch (e) {
      _showErrorDialog('Error capturing image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPrediction(String imagePath) {
    Navigator.pushNamed(
      context,
      '/prediction_page',
      arguments: {'imagePath': imagePath},
    );
  }

  void _showErrorDialog(String message) {
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Food AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                Text(
                  'AI-Powered Food Recognition',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _cameraInitialized ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_cameraInitialized ? Colors.green : Colors.orange).withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _cameraInitialized ? 'Ready' : 'Loading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade900,
              Colors.green.shade700,
              Colors.teal.shade800,
              Colors.cyan.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _cameraInitialized
          ? Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isLoading
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade600],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.green.shade200,
                          Colors.green.shade400,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _isLoading 
                        ? Colors.grey.withValues(alpha: 0.4)
                        : Colors.green.withValues(alpha: 0.5),
                    blurRadius: 35,
                    offset: const Offset(0, 18),
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLoading
                        ? Colors.grey.shade500
                        : Colors.white,
                    width: 4,
                  ),
                ),
                child: FloatingActionButton.large(
                  onPressed: _isLoading ? null : _captureImage,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isLoading
                          ? LinearGradient(
                              colors: [Colors.grey.shade500, Colors.grey.shade700],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                                Colors.green.shade800,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                      border: Border.all(
                        color: _isLoading
                            ? Colors.grey.shade400
                            : Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  // Inner circle
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Camera icon
                                  Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.green.shade700,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              )
            : null,
        color: isActive ? null : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && !_cameraInitialized) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                'Initializing Camera...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Setting up AI-powered food recognition',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraInitialized) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Not Available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check camera permissions and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: _initializeCamera,
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Enhanced Camera preview container - 75% of screen
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Camera preview with perfect container fit
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CameraService.getPreviewWidget(),
                      ),
                    ),
                  ),
                  
                  // Grid lines overlay - perfectly aligned with camera preview
                  if (!_isLoading && _showGrid)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CustomPaint(
                            painter: GridPainter(),
                          ),
                        ),
                      ),
                    ),
                  
                  // Enhanced focus area with animated border
                  if (!_isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green.shade400,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Animated corner brackets
                                ...List.generate(4, (index) {
                                  return Positioned(
                                    top: index < 2 ? 15 : null,
                                    bottom: index >= 2 ? 15 : null,
                                    left: index % 2 == 0 ? 15 : null,
                                    right: index % 2 == 1 ? 15 : null,
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 600 + (index * 100)),
                                      width: 25,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade400,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withValues(alpha: 0.6),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                
                                // Center focus dot
                                Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade400,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.8),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Minimal top overlay - removed AI Ready and HD Quality indicators
                  
                  // Bottom overlay with tips
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Place food in center frame for best results',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Compact control area - 25% of screen
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Removed AI Status and camera settings indicators
                    const SizedBox(height: 8),
                    // Control buttons
                    if (_cameraInitialized) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.grid_3x3,
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _showGrid = !_showGrid;
                              });
                            },
                            tooltip: 'Grid Lines',
                            isActive: _showGrid,
                          ),
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            onPressed: _isLoading ? null : () async {
                              await CameraService.switchCamera();
                              setState(() {});
                            },
                            tooltip: 'Switch Camera',
                          ),
                          _buildControlButton(
                            icon: CameraService.flashMode == FlashMode.off 
                                ? Icons.flash_off 
                                : Icons.flash_auto,
                            onPressed: _isLoading ? null : () async {
                              await CameraService.toggleFlash();
                              setState(() {});
                            },
                            tooltip: 'Toggle Flash',
                            isActive: CameraService.flashMode != FlashMode.off,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Enhanced Zoom Slider with actual camera control
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_currentZoom.toStringAsFixed(1)}x',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.zoom_out,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.black.withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.green.shade400,
                                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.green.withValues(alpha: 0.2),
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8,
                                        ),
                                        overlayShape: const RoundSliderOverlayShape(
                                          overlayRadius: 16,
                                        ),
                                        trackHeight: 4,
                                      ),
                                      child: Slider(
                                        value: _currentZoom,
                                        min: 1.0,
                                        max: 5.0,
                                        divisions: 40,
                                        onChanged: _isLoading ? null : (value) async {
                                          setState(() {
                                            _currentZoom = value;
                                          });
                                          try {
                                            await CameraService.setZoomLevel(value);
                                          } catch (e) {
                                            // Zoom error handled silently
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Helpful tip
                    Text(
                      'Place food in center frame for best AI recognition',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 100), // Space for floating button
        ],
      ),
    );
  }
}

// Custom painter for camera grid lines
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Add slight padding to ensure grid doesn't touch edges
    final double padding = 0.0;
    final double adjustedWidth = size.width - (padding * 2);
    final double adjustedHeight = size.height - (padding * 2);

    // Draw vertical lines (rule of thirds)
    final double thirdWidth = adjustedWidth / 3;
    canvas.drawLine(
      Offset(padding + thirdWidth, padding),
      Offset(padding + thirdWidth, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding + thirdWidth * 2, padding),
      Offset(padding + thirdWidth * 2, size.height - padding),
      paint,
    );

    // Draw horizontal lines (rule of thirds)
    final double thirdHeight = adjustedHeight / 3;
    canvas.drawLine(
      Offset(padding, padding + thirdHeight),
      Offset(size.width - padding, padding + thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(padding, padding + thirdHeight * 2),
      Offset(size.width - padding, padding + thirdHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}