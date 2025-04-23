import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FoodClassifier {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();

      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenetv2_food_model.tflite',
        options: options,
      );

      // Load labels
      final labelTxt = await rootBundle.loadString('assets/labels.txt');
      _labels =
          labelTxt
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      // Verify output shape matches labels
      final outputTensor = _interpreter.getOutputTensor(0);
      if (outputTensor.shape[1] != _labels.length) {
        throw Exception(
          'Model output shape (${outputTensor.shape[1]}) '
          'does not match labels count (${_labels.length})',
        );
      }

      _isModelLoaded = true;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<List<Map<String, dynamic>>> classifyImage(
    File imageFile, {
    int topK = 3,
  }) async {
    if (!_isModelLoaded) {
      throw Exception('Model is not loaded');
    }

    try {
      // Read and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final inputImage = img.copyResize(image, width: 224, height: 224);
      final inputBuffer = Float32List(224 * 224 * 3);

      // Normalize pixel values to [0,1]
      int pixelIndex = 0;
      for (var y = 0; y < inputImage.height; y++) {
        for (var x = 0; x < inputImage.width; x++) {
          final pixel = inputImage.getPixel(x, y);
          inputBuffer[pixelIndex++] = pixel.r / 255.0;
          inputBuffer[pixelIndex++] = pixel.g / 255.0;
          inputBuffer[pixelIndex++] = pixel.b / 255.0;
        }
      }

      // Reshape to model input format [1, 224, 224, 3]
      final input = inputBuffer.reshape([1, 224, 224, 3]);

      // Get output tensor shape dynamically
      final outputTensor = _interpreter.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final output = List.filled(outputShape[1], 0.0).reshape(outputShape);

      // Run inference
      _interpreter.run(input, output);

      // Get top predictions
      final predictions = <Map<String, dynamic>>[];
      for (int i = 0; i < _labels.length; i++) {
        predictions.add({'label': _labels[i], 'confidence': output[0][i]});
      }

      // Sort by confidence and take topK
      predictions.sort((a, b) => b['confidence'].compareTo(a['confidence']));
      return predictions.take(topK).toList();
    } catch (e) {
      throw Exception('Error during classification: $e');
    }
  }

  void dispose() {
    _interpreter.close();
  }
}
