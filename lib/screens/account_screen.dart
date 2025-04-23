import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  bool isEditing = false;
  Map<String, dynamic> userData = {};
  final _formKey = GlobalKey<FormState>();

  // Lists for dropdowns and chips
  final List<String> dietaryGoals = [
    "Weight Loss",
    "Improved Health",
    "Weight Gain",
  ];
  final List<String> dietaryRestrictions = [
    "None",
    "Vegetarian",
    "Vegan",
    "Gluten Free",
    "Dairy Free",
    "Nut Allergy",
  ];
  final List<String> activityLevels = [
    "Sedentary (Little or no exercise)",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
  ];
  final List<String> cuisinePreferences = [
    "Indian",
    "Mediterranean",
    "Keto",
    "Paleo",
    "High-Protein",
    "No Preference",
  ];
  final List<String> commonAllergies = [
    "Seafood",
    "Soy",
    "Eggs",
    "Shellfish",
    "Peanuts",
    "None",
  ];
  final List<String> healthConditions = [
    "None",
    "High Blood Pressure",
    "Diabetes",
    "High Cholesterol",
    "Kidney Disease",
    "Heart Disease",
  ];

  // Temporary lists for editing
  List<String> tempDietaryRestrictions = [];
  List<String> tempAllergies = [];
  List<String> tempHealthConditions = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (mounted) {
      setState(() {
        userData = doc.data() ?? {};
        // Initialize temp lists
        tempDietaryRestrictions = List<String>.from(
          userData['dietaryRestrictions'] ?? [],
        );
        tempAllergies = List<String>.from(userData['allergies'] ?? []);
        tempHealthConditions = List<String>.from(
          userData['healthConditions'] ?? [],
        );
      });
    }
  }

  Future<void> saveUserData() async {
    if (_formKey.currentState!.validate()) {
      // Update userData with temp values
      userData['dietaryRestrictions'] = tempDietaryRestrictions;
      userData['allergies'] = tempAllergies;
      userData['healthConditions'] = tempHealthConditions;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(userData);
      setState(() => isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  void _cancelEditing() {
    // Reset to original data
    fetchUserData();
    setState(() => isEditing = false);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String keyName, {
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: userData[keyName]?.toString() ?? '',
        enabled: isEditing,
        maxLines: multiline ? 3 : 1,
        style: TextStyle(
          color: isEditing ? Colors.black87 : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade600),
          filled: true,
          fillColor: isEditing ? Colors.teal.shade50 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon:
              isEditing
                  ? null
                  : Icon(Icons.lock_outline, size: 18, color: Colors.grey),
        ),
        onChanged: (val) => userData[keyName] = val,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String keyName, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: userData[keyName]?.toString(),
        items:
            items
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
        onChanged:
            isEditing
                ? (newValue) {
                  setState(() {
                    userData[keyName] = newValue;
                  });
                }
                : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade600),
          filled: true,
          fillColor: isEditing ? Colors.teal.shade50 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon:
              isEditing
                  ? null
                  : Icon(Icons.lock_outline, size: 18, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildChipsSelection(
    String label,
    List<String> selectedItems,
    List<String> allItems,
    Function(List<String>) onSelectionChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.teal.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isEditing ? Colors.teal.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  allItems.map((item) {
                    final isSelected = selectedItems.contains(item);
                    return FilterChip(
                      label: Text(item),
                      selected: isSelected,
                      backgroundColor:
                          isSelected
                              ? Colors.teal.shade100
                              : Colors.grey.shade200,
                      selectedColor: Colors.teal.shade200,
                      checkmarkColor: Colors.teal,
                      onSelected:
                          isEditing
                              ? (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedItems.add(item);
                                  } else {
                                    selectedItems.remove(item);
                                  }
                                  onSelectionChanged(selectedItems);
                                });
                              }
                              : null,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: saveUserData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, size: 20),
              SizedBox(width: 8),
              Text(
                'SAVE CHANGES',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            pinned: true,
            backgroundColor: Colors.teal, // Static teal color
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.close : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isEditing) {
                    _cancelEditing();
                  } else {
                    setState(() => isEditing = true);
                  }
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Personal Information'),
                    _buildTextField('Full Name', 'name'),
                    _buildTextField('Gender', 'gender'),
                    _buildTextField('Age', 'age'),

                    _buildSectionTitle('Body Metrics'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Height (cm)', 'height'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Weight (kg)', 'weight'),
                        ),
                      ],
                    ),
                    _buildTextField('Target Weight (kg)', 'targetWeight'),

                    _buildSectionTitle('Location'),
                    _buildTextField('Country', 'country'),
                    _buildTextField('State', 'state'),
                    _buildTextField('City', 'city'),

                    _buildSectionTitle('Diet Preferences'),
                    _buildDropdown('Dietary Goal', 'dietaryGoal', dietaryGoals),
                    _buildDropdown(
                      'Preferred Cuisine',
                      'preferredCuisine',
                      cuisinePreferences,
                    ),
                    _buildChipsSelection(
                      'Dietary Restrictions',
                      tempDietaryRestrictions,
                      dietaryRestrictions,
                      (newList) => tempDietaryRestrictions = newList,
                    ),
                    _buildChipsSelection(
                      'Allergies',
                      tempAllergies,
                      commonAllergies,
                      (newList) => tempAllergies = newList,
                    ),
                    _buildChipsSelection(
                      'Health Conditions',
                      tempHealthConditions,
                      healthConditions,
                      (newList) => tempHealthConditions = newList,
                    ),
                    _buildDropdown(
                      'Activity Level',
                      'activityLevel',
                      activityLevels,
                    ),

                    if (isEditing) _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
