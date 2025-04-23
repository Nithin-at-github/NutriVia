import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealHistoryPage extends StatelessWidget {
  const MealHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meal History',
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('food_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data!.docs;

          if (meals.isEmpty) {
            return const Center(
              child: Text(
                'No meals logged yet!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index].data() as Map<String, dynamic>;
              return _buildMealCard(context, meal);
            },
          );
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    final date = (meal['timestamp'] as Timestamp).toDate();
    final time = DateFormat('h:mm a').format(date);
    final nutrients = meal['nutrients'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Type and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  label: Text(
                    meal['mealType'].toString().toUpperCase(),
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${DateFormat('MMM d').format(date)} • $time',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              meal['description'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Nutrients
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildNutrientChip(
                  'Calories',
                  '${nutrients['Calories']?.toStringAsFixed(0) ?? '0'} kcal',
                ),
                _buildNutrientChip(
                  'Protein',
                  '${nutrients['Protein']?.toStringAsFixed(1) ?? '0'}g',
                ),
                _buildNutrientChip(
                  'Carbs',
                  '${nutrients['Carbs']?.toStringAsFixed(1) ?? '0'}g',
                ),
                _buildNutrientChip(
                  'Fat',
                  '${nutrients['Fat']?.toStringAsFixed(1) ?? '0'}g',
                ),
              ],
            ),

            // Image if available
            if (meal['imageUrl'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  meal['imageUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: Colors.teal[800], fontSize: 12),
      ),
    );
  }
}
