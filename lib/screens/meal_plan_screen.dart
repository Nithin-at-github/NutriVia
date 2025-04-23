import 'package:flutter/material.dart';
import 'package:nutrivia/models/meal_model.dart';
import 'package:nutrivia/services/meal_plan_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MealPlanScreen extends StatefulWidget {
  final String userId;

  const MealPlanScreen({super.key, required this.userId});

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanService _service = MealPlanService(
    nutritionixAppId: '',
    nutritionixAppKey: '',
  );
  Map<String, List<Meal>>? _plan;
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    // try {
    //   final plan = await _service.generatePlan(widget.userId);
    //   await _service.savePlan(widget.userId, plan);
    //   setState(() {
    //     _plan = plan;
    //     _isLoading = false;
    //   });
    // } catch (e) {
    //   setState(() => _isLoading = false);
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text('Failed to load plan: $e')));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Meal Plan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlan),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _plan == null
              ? const Center(child: Text('No meal plan available'))
              : ListView(
                children: [
                  _MealSection(
                    title: 'Breakfast',
                    meals: _plan!['breakfast']!,
                    icon: Icons.wb_sunny,
                  ),
                  _MealSection(
                    title: 'Lunch',
                    meals: _plan!['lunch']!,
                    icon: Icons.lunch_dining,
                  ),
                  _MealSection(
                    title: 'Dinner',
                    meals: _plan!['dinner']!,
                    icon: Icons.dinner_dining,
                  ),
                  _MealSection(
                    title: 'Snacks',
                    meals: _plan!['snacks']!,
                    icon: Icons.local_cafe,
                  ),
                ],
              ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<Meal> meals;
  final IconData icon;

  const _MealSection({
    required this.title,
    required this.meals,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.teal[800]),
              ),
            ],
          ),
        ),
        ...meals.map((meal) => _MealCard(meal: meal)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meal.imageUrl != null)
            CachedNetworkImage(
              imageUrl: meal.imageUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      Container(color: Colors.grey[200], height: 150),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[200],
                    height: 150,
                    child: const Icon(Icons.fastfood),
                  ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meal.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      meal.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _NutritionChip(label: '${meal.calories} cal'),
                    _NutritionChip(label: 'P: ${meal.protein}g'),
                    _NutritionChip(label: 'C: ${meal.carbs}g'),
                    _NutritionChip(label: 'F: ${meal.fat}g'),
                    if (meal.fiber > 0)
                      _NutritionChip(label: 'Fiber: ${meal.fiber}g'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Serving: ${meal.serving}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (meal.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      children:
                          meal.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;

  const _NutritionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.teal[50],
      labelStyle: TextStyle(color: Colors.teal[800], fontSize: 12),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
