import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:nutrivia/widgets/food_prediction_dialog.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:nutrivia/screens/portion_dialog.dart';
import '../services/nutrition_logging_service.dart';
import 'package:nutrivia/screens/meal_history_page.dart';
import 'package:nutrivia/services/food_classifier.dart';

class FoodScanPage extends StatefulWidget {
  final String? mealType;
  const FoodScanPage({super.key, this.mealType});

  @override
  State<FoodScanPage> createState() => _FoodScanPageState();
}

class _FoodScanPageState extends State<FoodScanPage>
    with WidgetsBindingObserver {
  final NutritionLoggingService _nutritionService =
      GetIt.instance<NutritionLoggingService>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _voiceTextController = TextEditingController();
  final FoodClassifier _foodClassifier = FoodClassifier();
  bool _isClassifying = false;
  List<Map<String, dynamic>> _imagePredictions = [];

  late stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _showPredictionDialog = false;
  List<String> _selectedFoods = [];

  File? _selectedImage;
  CameraController? _cameraController;
  bool _isCameraReady = false;
  // ignore: unused_field
  final bool _isRecording = false;
  bool _isLogging = false;
  String? _cameraError;
  late String _determinedMealType;
  bool _isLoadingCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determinedMealType = widget.mealType ?? _calculateMealTypeByTime();
    _initializeCamera();
    _initSpeech();
    _loadModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedImage != null) {
        _processImageAndShowPredictions();
      }
    });
  }

  Future<void> _loadModel() async {
    try {
      await _foodClassifier.loadModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load food model: $e')),
        );
      }
    }
  }

  void _initSpeech() async {
    _speechToText = stt.SpeechToText();
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _descriptionController.dispose();
    _voiceTextController.dispose();
    _foodClassifier.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCamera = true;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _isLoadingCamera = false;
      });
    } catch (e) {
      _handleCameraException(e);
    }
  }

  void _handleCameraException(dynamic e) {
    if (!mounted) return;

    setState(() {
      _isLoadingCamera = false;
      _isCameraReady = false;
      _cameraError = e.toString();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Camera error: ${e.toString()}')));
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera is not ready')));
      return;
    }

    try {
      final XFile file = await _cameraController!.takePicture();
      if (mounted) {
        setState(() => _selectedImage = File(file.path));
        await _processImageAndShowPredictions(); // Wait for prediction to complete
      }
    } catch (e) {
      _handleCameraException(e);
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
        await _processImageAndShowPredictions(); // Wait for prediction to complete
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _processImageAndShowPredictions() async {
    if (_selectedImage == null) return;

    setState(() => _isClassifying = true);

    try {
      final predictions = await _foodClassifier.classifyImage(_selectedImage!);

      if (mounted && predictions.isNotEmpty) {
        final selectedFood = await showDialog<String>(
          context: context,
          builder:
              (context) => FoodPredictionDialog(
                predictions: predictions,
                imageFile: _selectedImage!,
              ),
        );

        if (selectedFood != null && mounted) {
          // Add to description without navigating
          setState(() {
            _selectedFoods.add(selectedFood);
            _descriptionController.text = _selectedFoods.join(', ');
            _selectedImage = null; // Reset for next capture
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  String _calculateMealTypeByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 15) return 'Lunch';
    if (hour >= 15 && hour < 20) return 'Dinner';
    return 'Snack';
  }

  void _startListening() {
    _voiceTextController.clear();
    if (_speechEnabled) {
      setState(() {
        _isListening = true;
      });
      _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      _showVoiceInputDialog();
    } else {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _voiceTextController.text = result.recognizedWords;
    });
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Describe Your Food'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _voiceTextController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Say what you\'re eating...',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  AvatarGlow(
                    glowColor: Colors.teal,
                    endRadius: 75.0, // This should be fine
                    duration: const Duration(milliseconds: 2000),
                    // Replace repeatPauseDuration with this:
                    repeatPauseDuration: const Duration(
                      milliseconds: 100,
                    ), // This should be fine too
                    repeat: true,
                    animate: _isListening,
                    child: CircleAvatar(
                      backgroundColor: _isListening ? Colors.teal : Colors.grey,
                      radius: 35,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _stopListening();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_isListening) {
                      setDialogState(() {
                        _stopListening();
                      });
                    } else {
                      setDialogState(() {
                        _startListening();
                      });
                    }
                  },
                  child: Text(_isListening ? 'Stop' : 'Start'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _stopListening();
                    _descriptionController.text = _voiceTextController.text;
                    Navigator.pop(context);
                  },
                  child: const Text('Log Food'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleRecording() {
    _startListening();
  }

  Future<void> _logMeal() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your meal')),
      );
      return;
    }

    setState(() => _isLogging = true);

    try {
      final apiResponse = await _nutritionService.getNutritionData(
        _descriptionController.text,
      );

      final foods = (apiResponse['foods'] as List<dynamic>);

      final adjustedFoods = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder:
            (context) => PortionDialog(
              foodDescription: _descriptionController.text,
              foods: foods,
            ),
      );

      if (adjustedFoods != null && mounted) {
        await _nutritionService.logMealWithPortions(
          userId: FirebaseAuth.instance.currentUser!.uid,
          query: _descriptionController.text,
          mealType:
              _determinedMealType.toLowerCase() == 'breakfast'
                  ? MealType.breakfast
                  : _determinedMealType.toLowerCase() == 'lunch'
                  ? MealType.lunch
                  : _determinedMealType.toLowerCase() == 'dinner'
                  ? MealType.dinner
                  : MealType.snack,
          foods: adjustedFoods,
          imageFile: _selectedImage,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal logged successfully!')),
          );
          setState(() {
            _selectedFoods.clear();
            _descriptionController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log meal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  Widget _buildCameraPreview() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          Image.file(
            _selectedImage!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: () => setState(() => _selectedImage = null),
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      );
    }

    if (_isLoadingCamera) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraError != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text('Camera Error', style: TextStyle(color: Colors.red[700])),
          TextButton(onPressed: _initializeCamera, child: const Text('Retry')),
        ],
      );
    }

    if (_cameraController != null && _isCameraReady) {
      return CameraPreview(_cameraController!);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('Camera not available'),
        TextButton(
          onPressed: _initializeCamera,
          child: const Text('Initialize Camera'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log $_determinedMealType',
          style: const TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        actions: [
          if (_isLogging)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _logMeal,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Meal Type and Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Describe your $_determinedMealType",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Text(
                  DateFormat.jm().format(DateTime.now()),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Improved Description TextField
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'e.g., "Grilled chicken with rice and vegetables"',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 30),

            // Camera Preview or Image Display
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCameraPreview(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Take Photo Button
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isCameraReady ? _takePicture : null,
            ),
            const SizedBox(height: 15),

            // Alternative Options Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Button
                TextButton.icon(
                  icon: const Icon(Icons.photo_library, color: Colors.teal),
                  label: const Text('Gallery'),
                  onPressed: _getImageFromGallery,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),

                // Voice Logging Button
                TextButton.icon(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.teal,
                  ),
                  label: Text(_isListening ? 'Stop' : 'Voice'),
                  onPressed: _toggleRecording,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.history, size: 20),
              label: const Text('View Meal History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[100],
                foregroundColor: Colors.teal[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealHistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
