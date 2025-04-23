import 'dart:io';
import 'package:flutter/material.dart';

class FoodPredictionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  final File imageFile;

  const FoodPredictionDialog({
    super.key,
    required this.predictions,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Foods',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the correct item below',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Predictions list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prediction = predictions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Text(
                        '${(prediction['confidence'] * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(prediction['label']),
                    onTap: () => Navigator.pop(context, prediction['label']),
                  );
                },
              ),
            ),

            // Manual entry option
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Enter manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
