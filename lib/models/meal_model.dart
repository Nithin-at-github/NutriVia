class Meal {
  final String id;
  final String name;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final List<String> tags;
  final String serving;
  final String? imageUrl;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.tags,
    required this.serving,
    this.imageUrl,
  });

  // Add this method to convert Meal to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'tags': tags,
      'serving': serving,
      'imageUrl': imageUrl,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      protein: map['protein']?.toInt() ?? 0,
      carbs: map['carbs']?.toInt() ?? 0,
      fat: map['fat']?.toInt() ?? 0,
      fiber: map['fiber']?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      serving: map['serving'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}
