import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrivia/screens/home_screen.dart';

class SignupStep4 extends StatefulWidget {
  final String name;
  final int age;
  final String? gender;
  final double weight;
  final double height;
  final double bmi;
  final String bmiStatus;
  final String country;
  final String state;
  final String city;

  const SignupStep4({
    super.key,
    required this.name,
    required this.age,
    this.gender,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bmiStatus,
    required this.country,
    required this.state,
    required this.city,
  });

  @override
  _SignupStep4State createState() => _SignupStep4State();
}

class _SignupStep4State extends State<SignupStep4> {
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
  final List<String> mealFrequencies = [
    "3 Meals a Day",
    "5 Small Meals",
    "Intermittent Fasting",
  ];

  String? selectedGoal;
  String? selectedActivityLevel;
  String? selectedMealFrequency;
  String? selectedCuisine;
  List<String> selectedRestrictions = [];
  List<String> selectedAllergies = [];
  List<String> selectedConditions = [];
  final TextEditingController targetWeightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false; // Track loading state

  Future<void> saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not logged in!")));
        setState(() => isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "name": widget.name,
        "age": widget.age,
        "gender": widget.gender,
        "height": widget.height,
        "weight": widget.weight,
        "bmi": widget.bmi,
        "bmiStatus": widget.bmiStatus,
        "country": widget.country,
        "state": widget.state,
        "city": widget.city,
        "targetWeight": double.tryParse(targetWeightController.text) ?? 0.0,
        "dietaryGoal": selectedGoal,
        "dietaryRestrictions": selectedRestrictions,
        "allergies": selectedAllergies,
        "healthConditions": selectedConditions,
        "activityLevel": selectedActivityLevel,
        "preferredCuisine": selectedCuisine,
        "mealFrequency": selectedMealFrequency,
        "profileCompleted": true, // Mark profile as completed
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile saved successfully!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      ); // Redirect to home or dashboard
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text("Step 4: Dietary Preferences"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Step 4 of 4",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),

                // Dietary Goal
                DropdownButtonFormField<String>(
                  value: selectedGoal,
                  items:
                      dietaryGoals
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (newValue) => setState(() => selectedGoal = newValue),
                  decoration: InputDecoration(
                    labelText: "Dietary Goal",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null ? "Please select a dietary goal" : null,
                ),
                SizedBox(height: 20),

                // Target Weight
                TextFormField(
                  controller: targetWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Target Weight (kg)",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Enter your target weight"
                              : null,
                ),
                SizedBox(height: 20),

                // Activity Level
                DropdownButtonFormField<String>(
                  value: selectedActivityLevel,
                  items:
                      activityLevels
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (newValue) =>
                          setState(() => selectedActivityLevel = newValue),
                  decoration: InputDecoration(
                    labelText: "Activity Level",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null
                              ? "Please select an activity level"
                              : null,
                ),
                SizedBox(height: 20),

                // Dietary Restrictions
                MultiSelectDialogField(
                  items:
                      dietaryRestrictions
                          .map((e) => MultiSelectItem(e, e))
                          .toList(),
                  title: Text("Select Dietary Restrictions"),
                  buttonText: Text("Dietary Restrictions"),
                  onConfirm:
                      (results) => setState(
                        () => selectedRestrictions = List<String>.from(results),
                      ),
                ),
                SizedBox(height: 20),

                // Allergies
                MultiSelectDialogField(
                  items:
                      commonAllergies
                          .map((e) => MultiSelectItem(e, e))
                          .toList(),
                  title: Text("Select Allergies"),
                  buttonText: Text("Allergies"),
                  onConfirm:
                      (results) => setState(
                        () => selectedAllergies = List<String>.from(results),
                      ),
                ),
                SizedBox(height: 20),

                // Health Conditions
                MultiSelectDialogField(
                  items:
                      healthConditions
                          .map((e) => MultiSelectItem(e, e))
                          .toList(),
                  title: Text("Health Conditions"),
                  buttonText: Text("Health Conditions"),
                  onConfirm:
                      (results) => setState(
                        () => selectedConditions = List<String>.from(results),
                      ),
                ),
                SizedBox(height: 20),

                // Preferred Cuisine
                DropdownButtonFormField<String>(
                  value: selectedCuisine,
                  items:
                      cuisinePreferences
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (newValue) => setState(() => selectedCuisine = newValue),
                  decoration: InputDecoration(
                    labelText: "Preferred Cuisine",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Meal Frequency
                DropdownButtonFormField<String>(
                  value: selectedMealFrequency,
                  items:
                      mealFrequencies.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedMealFrequency = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Meal Frequency",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null
                              ? "Please select a meal frequency"
                              : null,
                ),
                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: isLoading ? null : saveUserData,
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              "Finish",
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
