import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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

      _analyzeFood();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture or select image: $e';
      });
    }
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
            // API Key management panel
            if (_apiKey == null || _isEditingKey) _buildApiKeyConfigCard(cardBgColor, primaryColor),

            const SizedBox(height: 16),

            // Image scanner container
            _buildImageScannerContainer(cardBgColor, primaryColor),

            const SizedBox(height: 20),

            // Action Buttons
            if (_apiKey != null && !_isLoading) _buildScannerActionsRow(primaryColor),

            // Loading state
            if (_isLoading) _buildLoadingWidget(primaryColor),

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

  Widget _buildLoadingWidget(Color primary) {
    return const SizedBox.shrink(); // Handled inside stack overlay
  }

  Widget _buildErrorCard() {
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
                    const Text(
                      'Scanning Failed',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage ?? 'Unknown error occurred.',
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
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
