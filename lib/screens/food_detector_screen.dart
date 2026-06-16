import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';

class FoodDetectorScreen extends StatefulWidget {
  const FoodDetectorScreen({super.key});

  @override
  State<FoodDetectorScreen> createState() => _FoodDetectorScreenState();
}

class _FoodDetectorScreenState extends State<FoodDetectorScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = const StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _apiKeyController = TextEditingController();

  String? _apiKey;
  bool _isEditingKey = false;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String _loadingMessage = '';
  FoodScanResult? _scanResult;
  String? _errorMessage;
  String? _currentLocality;
  bool _isLocationLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _fetchCurrentLocation();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // 1. Check if GPS location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocality = null;
          _isLocationLoading = false;
        });
        if (!mounted) return;
        _showLocationSettingsDialog(context);
        return;
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocality = null;
            _isLocationLoading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. General recommendations will be shown.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocality = null;
          _isLocationLoading = false;
        });
        if (!mounted) return;
        _showAppSettingsDialog(context);
        return;
      }

      // 3. Fetch location with fallback
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (e) {
        debugPrint('FoodDetectorScreen: getCurrentPosition with high accuracy failed: $e. Trying low accuracy...');
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          );
        } catch (e2) {
          debugPrint('FoodDetectorScreen: getCurrentPosition with low accuracy failed: $e2. Trying getLastKnownPosition...');
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? '';
          final state = placemark.administrativeArea ?? '';
          setState(() {
            if (city.isNotEmpty && state.isNotEmpty) {
              _currentLocality = "$city, $state";
            } else if (city.isNotEmpty) {
              _currentLocality = city;
            } else {
              _currentLocality = state;
            }
          });
        }
      } else {
        setState(() {
          _currentLocality = null;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _showLocationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121826),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Services Disabled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'GPS location services are turned off on your device. Please enable location services to find your city and suggest restaurants.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Enable GPS', style: TextStyle(color: Color(0xFFC7F000), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121826),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Location permissions are permanently denied. Please open App Settings and allow location permission for Fauji Fitness to use this feature.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFFC7F000), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await _storageService.loadGeminiKey();
    setState(() {
      _apiKey = key;
      if (key != null) {
        _apiKeyController.text = key;
      }
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Gemini API Key.')),
      );
      return;
    }
    await _storageService.saveGeminiKey(key);
    setState(() {
      _apiKey = key;
      _isEditingKey = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key saved successfully!')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
      _scanResult = null;
    });

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });

      if (_apiKey == null || _apiKey!.isEmpty) {
        _promptApiKeyAndAnalyze();
      } else {
        _analyzeFood();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture or select image: $e';
      });
    }
  }

  Future<void> _promptApiKeyAndAnalyze() async {
    final TextEditingController tempController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, color: Color(0xFFC7F000)),
                const SizedBox(width: 10),
                Text(
                  'Enter Gemini API Key',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'A Gemini API Key is required to scan the image and identify the nutrition details. Get one for free from Google AI Studio.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tempController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste API Key (AIzaSy...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final key = tempController.text.trim();
                if (key.isNotEmpty) {
                  await _storageService.saveGeminiKey(key);
                  setState(() {
                    _apiKey = key;
                    _apiKeyController.text = key;
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  _analyzeFood();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7F000),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save & Scan Food', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeFood() async {
    if (_imageBytes == null || _apiKey == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Opening scanner camera...';
    });

    // Simulate progressive scanner steps for a premium look
    final steps = [
      'Capturing food image...',
      'Analyzing texture and colors...',
      'Recognizing Pakistani / global recipe...',
      'Calculating calories and macros...',
    ];

    for (var i = 0; i < steps.length; i++) {
      if (!mounted || !_isLoading) return;
      setState(() {
        _loadingMessage = steps[i];
      });
      await Future.delayed(const Duration(milliseconds: 700));
    }

    try {
      final result = await GeminiService.scanFoodImage(
        imageBytes: _imageBytes!,
        apiKey: _apiKey!,
        locationName: _currentLocality,
      );

      setState(() {
        _scanResult = result;
        _isLoading = false;
        _errorMessage = null;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFC7F000);
    final cardBgColor = isDark ? const Color(0xFF121826) : const Color(0xFFF4F6F8);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Food Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              'Instant calories & macros detection',
              style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (_apiKey != null)
            IconButton(
              icon: Icon(_isEditingKey ? Icons.close : Icons.vpn_key_outlined, color: primaryColor),
              onPressed: () {
                setState(() {
                  _isEditingKey = !_isEditingKey;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image scanner container is prominent at the top
            _buildImageScannerContainer(cardBgColor, primaryColor),

            const SizedBox(height: 16),

            _buildLocationStatusBadge(primaryColor),

            const SizedBox(height: 16),

            // Action Buttons are always visible when not loading
            if (!_isLoading) _buildScannerActionsRow(primaryColor),

            const SizedBox(height: 16),

            // Info banner or API Key configuration card
            if (_apiKey == null || _isEditingKey) 
              _buildApiKeyConfigCard(cardBgColor, primaryColor),

            // Error state
            if (_errorMessage != null) _buildErrorCard(),

            // Result state
            if (_scanResult != null && !_isLoading && _errorMessage == null)
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildResultPanel(cardBgColor, primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyConfigCard(Color cardBg, Color primary) {
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Gemini API Key Required',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Food identification requires a Google Gemini API Key. Your key remains safe on your device and is never shared.',
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter API Key (AIzaSy...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.key, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Quick alert with instructions
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF121826),
                        title: const Text('Get Free API Key'),
                        content: const Text(
                          '1. Visit: https://aistudio.google.com/\n'
                          '2. Sign in with your Google account.\n'
                          '3. Click "Create API Key".\n'
                          '4. Copy and paste it here.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('OK', style: TextStyle(color: primary)),
                          )
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'How to get a free key?',
                    style: TextStyle(color: primary, fontSize: 13, decoration: TextDecoration.underline),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveApiKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageScannerContainer(Color cardBg, Color primary) {
    final hasImage = _imageBytes != null;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasImage ? primary.withValues(alpha: 0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: hasImage
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage)
              Image.memory(
                _imageBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fastfood_outlined, color: primary, size: 50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Your Meal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Capture or upload a picture of Pakistani, vegetables, junk or global food to identify nutrients.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
                    ),
                  ),
                ],
              ),

            // Scanning line animation overlay when loading
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerActionsRow(Color primary) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: Colors.black),
            label: const Text('Take Photo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: Icon(Icons.photo_library, color: primary),
            label: Text('Upload Image', style: TextStyle(color: primary, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildErrorCard() {
    final isGeminiDisabled = _errorMessage != null &&
        (_errorMessage!.contains('generativelanguage') ||
            _errorMessage!.contains('Gemini API has not been used') ||
            _errorMessage!.contains('403'));

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Card(
        color: const Color(0xFF2C1515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGeminiDisabled ? 'Gemini API Needs Activation' : 'Scanning Failed',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isGeminiDisabled
                          ? 'Your API key is registered, but the Gemini API is disabled in your Google Cloud Project. Please visit the activation URL to enable it.'
                          : (_errorMessage ?? 'Unknown error occurred.'),
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                    if (isGeminiDisabled) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'How to fix:\n'
                        '1. Open this URL in your web browser:\n'
                        'https://console.developers.google.com/apis/api/generativelanguage.googleapis.com/overview?project=22500728689\n'
                        '2. Tap "ENABLE" and wait 2 minutes.\n'
                        '3. Re-scan your food!',
                        style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(Color cardBg, Color primary) {
    if (_scanResult == null) return const SizedBox.shrink();

    if (!_scanResult!.isFood) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Card(
          color: const Color(0xFF1E1C15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No Food Detected',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scanResult!.description.isNotEmpty
                            ? _scanResult!.description
                            : 'Please capture a clear picture of a food item.',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Food Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _scanResult!.foodName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Detected',
                        style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _scanResult!.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calories Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.25), Colors.black26],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: CircularProgressIndicator(
                        value: 0.75, // Visual fill
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 32),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL CALORIES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_scanResult!.calories} kcal',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Macronutrients Title
          const Text(
            'Macronutrients Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Macro bars
          _buildMacroProgressBar('Protein', _scanResult!.protein, Colors.lightBlueAccent, 'Muscle Building'),
          const SizedBox(height: 12),
          _buildMacroProgressBar('Carbs', _scanResult!.carbs, Colors.amberAccent, 'Energy Source'),
          const SizedBox(height: 12),
          _buildMacroProgressBar('Fats', _scanResult!.fat, Colors.redAccent, 'Hormones & Cell Recovery'),

          const SizedBox(height: 24),

          // Restaurant suggestions section title
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Best Spots & Restaurants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currentLocality != null
                ? 'Top spots to try this in $_currentLocality'
                : 'Famous spots nationwide / globally',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 12),

          if (_scanResult!.restaurants.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(
                child: Text(
                  'No restaurant suggestions available.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            )
          else
            ..._scanResult!.restaurants.map((restaurant) => _buildRestaurantCard(restaurant, primary)),
        ],
      ),
    );
  }

  Widget _buildLocationStatusBadge(Color primary) {
    if (_isLocationLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF151B12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7F000))),
            ),
            SizedBox(width: 12),
            Text(
              'Fetching current location...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final hasLoc = _currentLocality != null && _currentLocality!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLoc ? primary.withValues(alpha: 0.2) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _fetchCurrentLocation,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                    hasLoc ? Icons.location_on : Icons.location_off_outlined,
                    color: hasLoc ? primary : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLoc ? 'Target Location' : 'Location Not Shared',
                          style: TextStyle(
                            color: hasLoc ? Colors.white70 : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasLoc ? _currentLocality! : 'General suggestions only',
                          style: TextStyle(
                            color: hasLoc ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: hasLoc ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.my_location, color: primary, size: 20),
            tooltip: 'Update Location',
            onPressed: _fetchCurrentLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantSpot spot, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side category bubble
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.restaurant, color: primary, size: 26),
          ),
          const SizedBox(width: 16),
          // Right side details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and open status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7F000).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFFC7F000)),
                          SizedBox(width: 4),
                          Text(
                            'OPEN NOW',
                            style: TextStyle(
                              color: Color(0xFFC7F000),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Rating, category, price
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      spot.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      '${spot.category} • ${spot.priceRange}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Delivery and distance
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      spot.deliveryTime,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.directions_bike_rounded, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      spot.distance,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                if (spot.specialty.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, color: primary, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Famous for: ${spot.specialty}',
                            style: TextStyle(
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Location Address
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        spot.address,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar(String name, double value, Color color, String role) {
    // Determine a reasonable max value for visualization (e.g. 100g max)
    final progress = (value / 80.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '${value.toStringAsFixed(1)}g',
                style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
