import 'package:flutter/material.dart';

class PortionDialog extends StatefulWidget {
  final String foodDescription;
  final List<dynamic> foods;

  const PortionDialog({
    super.key,
    required this.foodDescription,
    required this.foods,
  });

  @override
  State<PortionDialog> createState() => _PortionDialogState();
}

class _PortionDialogState extends State<PortionDialog> {
  late List<TextEditingController> _portionControllers;
  late List<String> _selectedUnits;
  final List<String> _allUnits = ['g', 'oz', 'mL', 'L']; // All available units

  @override
  void initState() {
    super.initState();
    _portionControllers = [];
    _selectedUnits = [];

    for (final food in widget.foods) {
      final isLiquid = _isLikelyLiquid(food);
      // Set defaults: 100 for solids, 50 for liquids
      final defaultQty = isLiquid ? '50' : '100';
      final defaultUnit = isLiquid ? 'mL' : 'g';

      _portionControllers.add(TextEditingController(text: defaultQty));
      _selectedUnits.add(defaultUnit);
    }
  }

  bool _isLikelyLiquid(Map<String, dynamic> food) {
    final name = food['food_name'].toString().toLowerCase();
    final unit = food['serving_unit'].toString().toLowerCase();

    // Explicit solid foods from the second code
    const solidKeywords = [
      'rice',
      'chicken',
      'curry',
      'roti',
      'naan',
      'biriyani',
      'vegetable',
      'dal',
      'paneer',
      'meat',
      'fish',
      'egg',
    ];

    // Combined liquid keywords from both codes
    const liquidKeywords = [
      'juice',
      'milk',
      'water',
      'soda',
      'tea',
      'coffee',
      'lassi',
      'soup',
      'shake',
      'smoothie',
      'buttermilk',
    ];

    // Check explicit liquid keywords first
    for (final keyword in liquidKeywords) {
      if (name.contains(keyword)) return true;
    }

    // Check explicit solid keywords next
    for (final keyword in solidKeywords) {
      if (name.contains(keyword)) return false;
    }

    // Fall back to unit-based detection
    return unit.contains('ml') || unit.contains('cup');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Portion Sizes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust portions for: ${widget.foodDescription}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...widget.foods.asMap().entries.map(
              (entry) => _buildFoodPortionRow(entry.key, entry.value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitPortions,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildFoodPortionRow(int index, Map<String, dynamic> food) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            food['food_name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _portionControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Quantity',
                    suffixText: _selectedUnits[index],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnits[index],
                  items:
                      _allUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                  onChanged: (newUnit) {
                    setState(() {
                      _selectedUnits[index] = newUnit!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitPortions() {
    final adjustedFoods =
        widget.foods.asMap().entries.map((entry) {
          final index = entry.key;
          final food = Map<String, dynamic>.from(
            entry.value,
          ); // Convert to ensure string keys
          final portion =
              double.tryParse(_portionControllers[index].text) ??
              (_selectedUnits[index] == 'g' ? 100 : 50);

          return {
            ...food,
            'serving_qty': portion,
            'serving_unit': _selectedUnits[index],
          };
        }).toList();

    Navigator.pop(context, adjustedFoods);
  }
}
