import 'dart:math';

import 'package:nutrivia/models/meal_model.dart';

class LocalMeals {
  // Complete Indian meal database
  static final Map<String, List<Meal>> _database = {
    'breakfast': [
      Meal(
        id: 'poha',
        name: 'Poha (Flattened Rice)',
        description:
            'Light rice flakes with turmeric, peanuts, and curry leaves',
        calories: 250,
        protein: 5,
        carbs: 45,
        fat: 5,
        fiber: 3,
        tags: ['vegetarian', 'gluten-free', 'quick'],
        serving: '1 bowl (150g)',
        imageUrl: 'assets/meals/poha.jpg',
      ),
      Meal(
        id: 'upma',
        name: 'Upma (Semolina Porridge)',
        description: 'Savory semolina cooked with vegetables and spices',
        calories: 300,
        protein: 8,
        carbs: 50,
        fat: 7,
        fiber: 4,
        tags: ['vegetarian', 'high-energy'],
        serving: '1 plate (200g)',
        imageUrl: 'assets/meals/upma.jpg',
      ),
      Meal(
        id: 'besan-chilla',
        name: 'Besan Chilla (Chickpea Pancake)',
        description: 'High-protein savory pancakes with herbs',
        calories: 280,
        protein: 15,
        carbs: 30,
        fat: 10,
        fiber: 5,
        tags: ['vegetarian', 'gluten-free', 'high-protein'],
        serving: '2 pieces (100g)',
        imageUrl: 'assets/meals/besan_chilla.jpg',
      ),
    ],
    'lunch': [
      Meal(
        id: 'dal-rice',
        name: 'Dal Tadka with Rice',
        description: 'Yellow lentils tempered with cumin and garlic',
        calories: 400,
        protein: 15,
        carbs: 60,
        fat: 10,
        fiber: 8,
        tags: ['vegetarian', 'gluten-free', 'balanced'],
        serving: '1 thali (300g)',
        imageUrl: 'assets/meals/dal_rice.jpg',
      ),
      Meal(
        id: 'roti-sabzi',
        name: 'Roti with Mixed Vegetables',
        description: 'Whole wheat flatbread with spiced seasonal veggies',
        calories: 350,
        protein: 12,
        carbs: 50,
        fat: 8,
        fiber: 7,
        tags: ['vegetarian', 'high-fiber'],
        serving: '2 rotis + 1 bowl sabzi',
        imageUrl: 'assets/meals/roti_sabzi.jpg',
      ),
      Meal(
        id: 'chicken-curry',
        name: 'Chicken Curry with Rice',
        description: 'Spicy chicken in onion-tomato gravy',
        calories: 450,
        protein: 30,
        carbs: 40,
        fat: 15,
        fiber: 3,
        tags: ['high-protein', 'non-vegetarian'],
        serving: '1 plate (350g)',
        imageUrl: 'assets/meals/chicken_curry.jpg',
      ),
    ],
    'dinner': [
      Meal(
        id: 'khichdi',
        name: 'Vegetable Khichdi',
        description: 'Rice-lentil porridge with ghee and vegetables',
        calories: 350,
        protein: 12,
        carbs: 55,
        fat: 8,
        fiber: 6,
        tags: ['vegetarian', 'gluten-free', 'easy-digest'],
        serving: '1 bowl (250g)',
        imageUrl: 'assets/meals/khichdi.jpg',
      ),
      Meal(
        id: 'palak-paneer',
        name: 'Palak Paneer with Roti',
        description: 'Spinach and cottage cheese in creamy gravy',
        calories: 380,
        protein: 20,
        carbs: 30,
        fat: 15,
        fiber: 5,
        tags: ['vegetarian', 'high-calcium'],
        serving: '2 rotis + 1 bowl curry',
        imageUrl: 'assets/meals/palak_paneer.jpg',
      ),
      Meal(
        id: 'fish-curry',
        name: 'Fish Curry with Rice',
        description: 'Fish in coconut-based gravy with spices',
        calories: 400,
        protein: 25,
        carbs: 35,
        fat: 12,
        fiber: 2,
        tags: ['non-vegetarian', 'omega-3'],
        serving: '1 plate (300g)',
        imageUrl: 'assets/meals/fish_curry.jpg',
      ),
    ],
    'snacks': [
      Meal(
        id: 'sprouts-chaat',
        name: 'Sprouted Moong Chaat',
        description: 'Sprouted lentils with onions, tomatoes, and spices',
        calories: 150,
        protein: 8,
        carbs: 20,
        fat: 3,
        fiber: 5,
        tags: ['vegetarian', 'high-fiber', 'protein-rich'],
        serving: '1 bowl (100g)',
        imageUrl: 'assets/meals/sprouts_chaat.jpg',
      ),
      Meal(
        id: 'masala-chai',
        name: 'Masala Chai with Almonds',
        description: 'Spiced tea with crushed almonds',
        calories: 120,
        protein: 3,
        carbs: 15,
        fat: 5,
        fiber: 1,
        tags: ['vegetarian', 'low-calorie'],
        serving: '1 cup (200ml)',
        imageUrl: 'assets/meals/masala_chai.jpg',
      ),
      Meal(
        id: 'fruit-chat',
        name: 'Fruit Chaat',
        description: 'Seasonal fruits with chaat masala and lemon',
        calories: 100,
        protein: 1,
        carbs: 25,
        fat: 0,
        fiber: 3,
        tags: ['vegetarian', 'vitamin-c', 'low-fat'],
        serving: '1 bowl (150g)',
        imageUrl: 'assets/meals/fruit_chaat.jpg',
      ),
    ],
  };

  // 1. Get ONE random meal per category that meets filters
  static Map<String, Meal?> getDailyMeals({
    required bool vegetarian,
    required bool lowCarb,
    required List<String> allergies,
  }) {
    final random = Random();

    Meal? getRandomMeal(String category) {
      final filtered =
          _database[category]?.where((meal) {
            if (vegetarian && !meal.tags.contains('vegetarian')) return false;
            if (lowCarb && meal.carbs > 30) return false;
            if (allergies.any((a) => !meal.tags.contains(a))) return false;
            return true;
          }).toList();

      return filtered?.isNotEmpty == true
          ? filtered![random.nextInt(filtered.length)]
          : null;
    }

    return {
      'breakfast': getRandomMeal('breakfast'),
      'lunch': getRandomMeal('lunch'),
      'dinner': getRandomMeal('dinner'),
      'snacks': getRandomMeal('snacks'),
    };
  }
}
