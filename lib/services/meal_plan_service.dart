import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nutrivia/models/meal_model.dart';
import 'package:nutrivia/services/local_meals.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _nutritionixAppId;
  final String _nutritionixAppKey;

  MealPlanService({
    required String nutritionixAppId,
    required String nutritionixAppKey,
  }) : _nutritionixAppId = nutritionixAppId,
       _nutritionixAppKey = nutritionixAppKey;

  // 1. Main method to get daily plan (Firebase first, then fallback)
  Future<Map<String, Meal?>> getDailyPlan({
    required String userId,
    required DateTime date,
  }) async {
    // Try Firebase first
    final firebasePlan = await _getPlanFromFirebase(userId, date);
    if (firebasePlan != null) return firebasePlan;

    // Fallback to generated plan
    return await _generateAndSavePlan(userId, date);
  }

  // 2. Check Firebase for existing plan
  Future<Map<String, Meal?>?> _getPlanFromFirebase(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('meal_plans')
              .doc(dateStr)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'breakfast':
              data['breakfast'] != null
                  ? Meal.fromMap(data['breakfast'])
                  : null,
          'lunch': data['lunch'] != null ? Meal.fromMap(data['lunch']) : null,
          'dinner':
              data['dinner'] != null ? Meal.fromMap(data['dinner']) : null,
          'snacks':
              data['snacks'] != null ? Meal.fromMap(data['snacks']) : null,
        };
      }
    } catch (e) {
      print('Error fetching from Firebase: $e');
    }
    return null;
  }

  // 3. Generate new plan (Nutritionix API first, then local fallback)
  Future<Map<String, Meal?>> _generateAndSavePlan(
    String userId,
    DateTime date,
  ) async {
    final prefs = await _getUserPreferences(userId);
    Map<String, Meal?> generatedPlan;

    try {
      // Try Nutritionix API first
      generatedPlan = await _generateWithNutritionix(prefs);
    } catch (e) {
      print('Falling back to local meals: $e');
      // Local fallback
      generatedPlan = LocalMeals.getDailyMeals(
        vegetarian:
            prefs['dietaryRestrictions']?.contains('vegetarian') ?? false,
        lowCarb: prefs['healthConditions']?.contains('diabetes') ?? false,
        allergies: prefs['allergies'] ?? [],
      );
    }

    // Save to Firebase
    await _savePlanToFirebase(userId, date, generatedPlan);
    return generatedPlan;
  }

  // 4. Generate using Nutritionix API
  Future<Map<String, Meal?>> _generateWithNutritionix(
    Map<String, dynamic> prefs,
  ) async {
    final isVeg = prefs['dietaryRestrictions']?.contains('vegetarian') ?? false;
    final hasDiabetes =
        prefs['healthConditions']?.contains('diabetes') ?? false;
    final cuisine = prefs['preferredCuisine'] ?? 'indian';
    final dailyCalories = prefs['dailyCalories'] ?? 1800;

    // Calculate meal calorie targets
    final targets = {
      'breakfast': (dailyCalories * 0.25).round(),
      'lunch': (dailyCalories * 0.35).round(),
      'dinner': (dailyCalories * 0.3).round(),
      'snacks': (dailyCalories * 0.1).round(),
    };

    final results = await Future.wait([
      _searchNutritionix(
        query: '$cuisine breakfast',
        isVeg: isVeg,
        hasDiabetes: hasDiabetes,
        targetCalories: targets['breakfast']!,
      ),
      _searchNutritionix(
        query: '$cuisine lunch',
        isVeg: isVeg,
        hasDiabetes: hasDiabetes,
        targetCalories: targets['lunch']!,
      ),
      _searchNutritionix(
        query: '$cuisine dinner',
        isVeg: isVeg,
        hasDiabetes: hasDiabetes,
        targetCalories: targets['dinner']!,
      ),
      _searchNutritionix(
        query: '$cuisine snack',
        isVeg: isVeg,
        hasDiabetes: hasDiabetes,
        targetCalories: targets['snacks']!,
        maxResults: 2,
      ),
    ]);

    return {
      'breakfast': results[0].isNotEmpty ? results[0].first : null,
      'lunch': results[1].isNotEmpty ? results[1].first : null,
      'dinner': results[2].isNotEmpty ? results[2].first : null,
      'snacks': results[3].isNotEmpty ? results[3].first : null,
    };
  }

  // 5. Nutritionix API search
  Future<List<Meal>> _searchNutritionix({
    required String query,
    required bool isVeg,
    required bool hasDiabetes,
    required int targetCalories,
    int maxResults = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://trackapi.nutritionix.com/v2/search/instant?query=$query',
        ),
        headers: {
          'x-app-id': _nutritionixAppId,
          'x-app-key': _nutritionixAppKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['common'] as List?) ?? [];

        return items
            .where((item) {
              // Filter based on preferences
              if (isVeg && (item['tags']?.contains('vegetarian') != true)) {
                return false;
              }
              if (hasDiabetes && (item['nf_total_carbohydrate'] ?? 0) > 30) {
                return false;
              }
              // Calorie range ±20%
              final calories = item['nf_calories'] ?? 0;
              return calories >= targetCalories * 0.8 &&
                  calories <= targetCalories * 1.2;
            })
            .take(maxResults)
            .map((item) {
              return Meal(
                id: item['food_name'].toString().toLowerCase().replaceAll(
                  ' ',
                  '-',
                ),
                name: item['food_name'] ?? 'Unknown',
                description: '',
                calories: (item['nf_calories'] ?? 0).round(),
                protein: (item['nf_protein'] ?? 0).round(),
                carbs: (item['nf_total_carbohydrate'] ?? 0).round(),
                fat: (item['nf_total_fat'] ?? 0).round(),
                fiber: (item['nf_dietary_fiber'] ?? 0).round(),
                tags: [if (isVeg) 'vegetarian', if (hasDiabetes) 'low-carb'],
                serving:
                    '${item['serving_qty'] ?? 1} ${item['serving_unit'] ?? 'serving'}',
                imageUrl: item['photo']?['thumb'],
              );
            })
            .toList();
      }
    } catch (e) {
      print('Nutritionix search error: $e');
    }
    return [];
  }

  // 6. Save plan to Firebase
  Future<void> _savePlanToFirebase(
    String userId,
    DateTime date,
    Map<String, Meal?> plan,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_plans')
          .doc(dateStr)
          .set({
            'breakfast': plan['breakfast']?.toMap(),
            'lunch': plan['lunch']?.toMap(),
            'dinner': plan['dinner']?.toMap(),
            'snacks': plan['snacks']?.toMap(),
            'generatedAt': FieldValue.serverTimestamp(),
            'source': plan['breakfast'] == null ? 'local' : 'nutritionix',
          });
    } catch (e) {
      print('Error saving to Firebase: $e');
    }
  }

  // 7. Get user preferences
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error fetching user prefs: $e');
      return {};
    }
  }

  // 8. Force refresh plan
  Future<void> refreshPlan(String userId, DateTime date) async {
    await _generateAndSavePlan(userId, date);
  }
}
