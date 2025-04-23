import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum MealType { breakfast, lunch, dinner, snack }

class NutritionLoggingService {
  static const String _baseUrl = 'https://trackapi.nutritionix.com/v2/';
  final String appId;
  final String appKey;

  NutritionLoggingService({required this.appId, required this.appKey});

  Future<Map<String, dynamic>> getNutritionData(String query) async {
    final url = Uri.parse('${_baseUrl}natural/nutrients');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-app-id': appId,
        'x-app-key': appKey,
      },
      body: jsonEncode({'query': query, 'timezone': 'US/Eastern'}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load nutrition data: ${response.statusCode}');
    }
  }

  Future<String> _uploadFoodImage(String userId, File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'food_images/$userId/${DateTime.now().millisecondsSinceEpoch}',
      );
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> logMeal({
    required String userId,
    required String query,
    required MealType mealType,
    File? imageFile,
  }) async {
    try {
      // 1. Get nutrition data
      final apiResponse = await getNutritionData(query);

      // 2. Upload image if exists
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadFoodImage(userId, imageFile);
      }

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timestamp = DateTime.now();

      // 3. Create food log document in user's subcollection
      final foodLogRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('food_logs')
              .doc(); // Auto-generated ID for individual meal

      // 4. Prepare the food entry
      final foodEntry = {
        'description': query,
        'nutrients': _extractNutrients(apiResponse),
        'mealType': mealType.toString().split('.').last,
        'date': date,
        'timestamp': timestamp,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      // 5. Create the food log document
      await foodLogRef.set(foodEntry);

      // 6. Update daily nutrients in user's subcollection
      final nutrientUpdates = _getNutrientUpdates(apiResponse);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_nutrients')
          .doc(date)
          .set(nutrientUpdates, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to log meal: $e');
    }
  }

  Map<String, dynamic> _extractNutrients(Map<String, dynamic> apiResponse) {
    final foods = apiResponse['foods'] as List;
    final nutrients = {
      'Calories': 0.0,
      'Protein': 0.0,
      'Carbs': 0.0,
      'Fat': 0.0,
      'Fiber': 0.0,
      'Sugar': 0.0,
      'Sodium': 0.0,
      'Cholesterol': 0.0,
    };

    for (final food in foods) {
      nutrients['Calories'] =
          (nutrients['Calories'] ?? 0) + (food['nf_calories'] ?? 0).toDouble();
      nutrients['Protein'] =
          (nutrients['Protein'] ?? 0) + (food['nf_protein'] ?? 0).toDouble();
      nutrients['Carbs'] =
          (nutrients['Carbs'] ?? 0) +
          (food['nf_total_carbohydrate'] ?? 0).toDouble();
      nutrients['Fat'] =
          (nutrients['Fat'] ?? 0) + (food['nf_total_fat'] ?? 0).toDouble();
      nutrients['Fiber'] =
          (nutrients['Fiber'] ?? 0) +
          (food['nf_dietary_fiber'] ?? 0).toDouble();
      nutrients['Sugar'] =
          (nutrients['Sugar'] ?? 0) + (food['nf_sugars'] ?? 0).toDouble();
      nutrients['Sodium'] =
          (nutrients['Sodium'] ?? 0) + (food['nf_sodium'] ?? 0).toDouble();
      nutrients['Cholesterol'] =
          (nutrients['Cholesterol'] ?? 0) +
          (food['nf_cholesterol'] ?? 0).toDouble();
    }

    return nutrients;
  }

  Map<String, dynamic> _getNutrientUpdates(Map<String, dynamic> apiResponse) {
    final foods = apiResponse['foods'] as List;
    final updates = <String, dynamic>{};

    for (final food in foods) {
      updates['Calories'] = FieldValue.increment(
        (food['nf_calories'] ?? 0).toDouble(),
      );
      updates['Protein'] = FieldValue.increment(
        (food['nf_protein'] ?? 0).toDouble(),
      );
      updates['Carbs'] = FieldValue.increment(
        (food['nf_total_carbohydrate'] ?? 0).toDouble(),
      );
      updates['Fat'] = FieldValue.increment(
        (food['nf_total_fat'] ?? 0).toDouble(),
      );
      updates['Fiber'] = FieldValue.increment(
        (food['nf_dietary_fiber'] ?? 0).toDouble(),
      );
      updates['Sugar'] = FieldValue.increment(
        (food['nf_sugars'] ?? 0).toDouble(),
      );
      updates['Sodium'] = FieldValue.increment(
        (food['nf_sodium'] ?? 0).toDouble(),
      );
      updates['Cholesterol'] = FieldValue.increment(
        (food['nf_cholesterol'] ?? 0).toDouble(),
      );
    }

    // Add date field if document is being created
    updates['date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    updates['lastUpdated'] = FieldValue.serverTimestamp();

    return updates;
  }

  // New method to get food logs for a specific date
  Stream<QuerySnapshot> getFoodLogsByDate(String userId, String date) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('food_logs')
        .where('date', isEqualTo: date)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // New method to get daily nutrients
  Future<DocumentSnapshot> getDailyNutrients(String userId, String date) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_nutrients')
        .doc(date)
        .get();
  }

  Future<void> logMealWithPortions({
    required String userId,
    required String query,
    required MealType mealType,
    required List<Map<String, dynamic>> foods,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadFoodImage(userId, imageFile);
      }

      // Calculate ALL nutrients (not just calories/protein/carbs/fat)
      final nutrients = {
        'Calories': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_calories'] ?? 0),
        ),
        'Protein': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_protein'] ?? 0),
        ),
        'Carbs': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_total_carbohydrate'] ?? 0),
        ),
        'Fat': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_total_fat'] ?? 0),
        ),
        'Fiber': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_dietary_fiber'] ?? 0),
        ),
        'Sugar': foods.fold(0.0, (sum, food) => sum + (food['nf_sugars'] ?? 0)),
        'Sodium': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_sodium'] ?? 0),
        ),
        'Cholesterol': foods.fold(
          0.0,
          (sum, food) => sum + (food['nf_cholesterol'] ?? 0),
        ),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('food_logs')
          .add({
            'description': query,
            'mealType': mealType.toString().split('.').last,
            'nutrients': nutrients,
            'timestamp': FieldValue.serverTimestamp(),
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            if (imageUrl != null) 'imageUrl': imageUrl,
            'portions':
                foods
                    .map(
                      (f) => {
                        'name': f['food_name'],
                        'quantity': f['serving_qty'],
                        'unit': f['serving_unit'],
                      },
                    )
                    .toList(),
          });

      await _updateDailyNutrients(userId, nutrients); // Now this will work
    } catch (e) {
      throw Exception('Failed to log meal: $e');
    }
  }

  Future<void> _updateDailyNutrients(
    String userId,
    Map<String, dynamic> nutrients,
  ) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final dailyUpdate = {
      'date': date,
      'lastUpdated': FieldValue.serverTimestamp(),
      'Calories': FieldValue.increment(nutrients['Calories']?.toDouble() ?? 0),
      'Protein': FieldValue.increment(nutrients['Protein']?.toDouble() ?? 0),
      'Carbs': FieldValue.increment(nutrients['Carbs']?.toDouble() ?? 0),
      'Fat': FieldValue.increment(nutrients['Fat']?.toDouble() ?? 0),
      'Fiber': FieldValue.increment(nutrients['Fiber']?.toDouble() ?? 0),
      'Sugar': FieldValue.increment(nutrients['Sugar']?.toDouble() ?? 0),
      'Sodium': FieldValue.increment(nutrients['Sodium']?.toDouble() ?? 0),
      'Cholesterol': FieldValue.increment(
        nutrients['Cholesterol']?.toDouble() ?? 0,
      ),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_nutrients')
        .doc(date)
        .set(dailyUpdate, SetOptions(merge: true));
  }
}
