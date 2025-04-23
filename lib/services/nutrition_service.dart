import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logFoodIntake(
    String userId,
    Map<String, int> consumedNutrients,
  ) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference dailyDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_nutrients')
        .doc(today);

    await dailyDoc.set(consumedNutrients, SetOptions(merge: true));
  }

  Future<void> calculateAndStoreNutrition(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) return;
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    double weight = userData['weight'];
    double height = userData['height'];
    int age = userData['age'];
    String gender = userData['gender'];
    String activityLevel = userData['activityLevel'];
    String dietaryGoal = userData['dietaryGoal'];
    List<String> dietaryRestrictions = List<String>.from(
      userData['dietaryRestrictions'] ?? [],
    );

    // Calculate BMI
    double bmi = weight / ((height / 100) * (height / 100));

    // Calculate BMR
    double bmr =
        (gender == 'Male')
            ? (10 * weight) + (6.25 * height) - (5 * age) + 5
            : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    // Calculate TDEE based on activity level
    Map<String, double> activityMultipliers = {
      'Sedentary': 1.2,
      'Lightly Active': 1.375,
      'Moderately Active': 1.55,
      'Very Active': 1.725,
      'Super Active': 1.9,
    };
    double tdee = bmr * (activityMultipliers[activityLevel] ?? 1.2);

    // Calculate macronutrient distribution
    Map<String, double> dailyMacros = _calculateMacronutrients(
      tdee,
      dietaryGoal,
    );

    // Personalize recommended nutrient intake based on user data
    Map<String, double> recommendedNutrients = _calculateRecommendedNutrients(
      weight,
      age,
      gender,
      dietaryRestrictions,
      dietaryGoal,
    );

    // Store calculated values in Firestore
    await _firestore.collection('users').doc(userId).update({
      'bmi': bmi,
      'bmr': bmr,
      'tdee': tdee,
      'dailyCalories': dailyMacros['Calories'],
      'dailyProtein': dailyMacros['Protein'],
      'dailyFat': dailyMacros['Fat'],
      'dailyCarbs': dailyMacros['Carbs'],
      'recommendedNutrients': recommendedNutrients,
    });

    // Initialize daily intake values if missing
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference todayDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_nutrients')
        .doc(today);

    DocumentSnapshot dailyDoc = await todayDoc.get();

    if (!dailyDoc.exists) {
      await todayDoc.set({
        'Calories': 0,
        'Protein': 0,
        'Fat': 0,
        'Carbs': 0,
        for (var key in recommendedNutrients.keys)
          key: 0, // Initialize all to 0
      });
    }
  }

  Map<String, double> _calculateMacronutrients(
    double tdee,
    String dietaryGoal,
  ) {
    double proteinPercentage, fatPercentage, carbPercentage;

    if (dietaryGoal == 'Weight Loss') {
      proteinPercentage = 0.30;
      fatPercentage = 0.25;
      carbPercentage = 0.45;
    } else if (dietaryGoal == 'Muscle Gain') {
      proteinPercentage = 0.35;
      fatPercentage = 0.20;
      carbPercentage = 0.45;
    } else {
      // Default for "Improved Health" and other goals
      proteinPercentage = 0.25;
      fatPercentage = 0.25;
      carbPercentage = 0.50;
    }

    return {
      'Calories': tdee.roundToDouble(),
      'Protein':
          ((tdee * proteinPercentage) / 4)
              .roundToDouble(), // 1g protein = 4 kcal
      'Fat': ((tdee * fatPercentage) / 9).roundToDouble(), // 1g fat = 9 kcal
      'Carbs':
          ((tdee * carbPercentage) / 4).roundToDouble(), // 1g carbs = 4 kcal
    };
  }

  Map<String, double> _calculateRecommendedNutrients(
    double weight,
    int age,
    String gender,
    List<String> dietaryRestrictions,
    String dietaryGoal,
  ) {
    return {
      'Cholesterol': gender == 'Male' ? 300.0 : 250.0,
      'Omega-3': dietaryRestrictions.contains('Vegan') ? 1.1 : 1.6,
      'Fiber': age > 50 ? 30.0 : 25.0,
      'Water': weight * 0.033,
      'Saturated Fat': 20.0,
      'Sodium': 2300.0,
      'Sugar': dietaryGoal == 'Improved Health' ? 30.0 : 50.0,
      'Trans Fat': 0.0,
      'Caffeine': 400.0,
      'Alcohol': 0.0,
      'Vitamin D': 15.0,
      'Vitamin B12': 2.4,
      'Vitamin C': dietaryRestrictions.contains('Vegan') ? 90.0 : 75.0,
      'Vitamin B9': 400.0,
      'Vitamin A': gender == 'Male' ? 900.0 : 700.0,
      'Iron': gender == 'Female' && age < 50 ? 18.0 : 8.0,
      'Calcium': dietaryRestrictions.contains('Dairy-Free') ? 1000.0 : 1200.0,
      'Magnesium': gender == 'Male' ? 420.0 : 320.0,
      'Zinc': gender == 'Male' ? 11.0 : 8.0,
      'Potassium': 4700.0,
    };
  }
}
