import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrivia/screens/exercise_logging_screen.dart';
import 'package:nutrivia/screens/food_scan_screen.dart';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  _FoodLoggingScreenState createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> dailyData = {};
  Map<String, dynamic> userData = {};
  bool isLoading = false;
  List<Map<String, dynamic>> foodLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await fetchUserData();
        await fetchDailyData();
        await fetchFoodLogs();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchFoodLogs() async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      String userId = FirebaseAuth.instance.currentUser!.uid;
      print("Fetching logs for date: $formattedDate"); // Debug

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('food_logs')
              .where('date', isEqualTo: formattedDate)
              .orderBy('timestamp', descending: true)
              .get();

      print("Found ${querySnapshot.docs.length} logs"); // Debug

      setState(() {
        foodLogs =
            querySnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              print("Log: ${data['description']}"); // Debug
              return {
                'id': doc.id,
                'mealType': data['mealType'],
                'description': data['description'],
                'calories':
                    (data['nutrients']['Calories'] as num?)?.toDouble() ?? 0.0,
                'timestamp': data['timestamp'],
              };
            }).toList();
      });
    } catch (e) {
      print("Error fetching logs: $e"); // Debug
      _showErrorSnackbar('Error loading food logs: ${e.toString()}');
    }
  }

  // Helper method to format numbers with max 2 decimals
  String _formatDouble(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  double calculateRecommendedWater(double weight, String activityLevel) {
    double activityFactor = 0.03; // Default for sedentary
    if (activityLevel == "Moderately Active") {
      activityFactor = 0.04;
    } else if (activityLevel == "Highly Active") {
      activityFactor = 0.05;
    }
    return weight * activityFactor;
  }

  Future<void> fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        setState(() {
          userData = userSnapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching user data');
      rethrow;
    }
  }

  Future<void> fetchDailyData() async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch exercise data
      var exerciseSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('exercise_logs')
              .doc(formattedDate)
              .get();
      double exerciseCalories =
          (exerciseSnapshot.data()?['totalCalories'] as num?)?.toDouble() ??
          0.0;

      // Fetch and process food logs
      QuerySnapshot foodLogsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('food_logs')
              .where('date', isEqualTo: formattedDate)
              .get();

      double foodCalories = 0.0;
      double protein = 0.0;
      double fat = 0.0;
      double carbs = 0.0;
      List<Map<String, dynamic>> foodLogs = [];

      for (var doc in foodLogsSnapshot.docs) {
        final log = doc.data() as Map<String, dynamic>;
        final nutrients = log['nutrients'] as Map<String, dynamic>? ?? {};

        foodCalories += (nutrients['Calories'] as num?)?.toDouble() ?? 0.0;
        protein += (nutrients['Protein'] as num?)?.toDouble() ?? 0.0;
        fat += (nutrients['Fat'] as num?)?.toDouble() ?? 0.0;
        carbs += (nutrients['Carbs'] as num?)?.toDouble() ?? 0.0;

        foodLogs.add({
          'id': doc.id,
          'mealType': log['mealType'] as String,
          'description': log['description'] as String,
          'calories': (nutrients['Calories'] as num?)?.toDouble() ?? 0.0,
          'timestamp': log['timestamp'] as Timestamp,
        });
      }

      // Group logs by meal type
      Map<String, List<Map<String, dynamic>>> mealsByType = {
        'Breakfast': [],
        'Lunch': [],
        'Dinner': [],
        'Snack': [],
      };
      for (var log in foodLogs) {
        mealsByType[log['mealType']]?.add(log);
      }

      // Get latest log per meal type
      Map<String, Map<String, dynamic>> latestMealLogs = {};
      mealsByType.forEach((mealType, logs) {
        if (logs.isNotEmpty) {
          logs.sort(
            (a, b) => (b['timestamp'] as Timestamp).compareTo(
              a['timestamp'] as Timestamp,
            ),
          );
          latestMealLogs[mealType] = logs.first;
        }
      });

      // Calculate recommended water
      double weight = (userData['weight'] as num?)?.toDouble() ?? 70.0;
      String activityLevel = userData['activityLevel'] ?? "Sedentary";
      double recommendedWater =
          calculateRecommendedWater(weight, activityLevel) * 1000;

      // Update state
      setState(() {
        dailyData = {
          'targetCalories':
              (userData['dailyCalories'] as num?)?.toDouble() ?? 2000.0,
          'exerciseCalories': exerciseCalories,
          'foodCalories': foodCalories,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
          'remainingCalories':
              ((userData['dailyCalories'] as num?)?.toDouble() ?? 2000.0) -
              foodCalories +
              exerciseCalories,
          'waterIntake': dailyData['waterIntake'] ?? 0.0,
          'recommendedWater': recommendedWater,
          'foodLogs': foodLogs,
          'latestMealLogs': latestMealLogs,
        };
      });
    } catch (e) {
      _showErrorSnackbar('Error fetching daily data: ${e.toString()}');
    }
  }

  Future<void> _addWater(int amount) async {
    try {
      setState(() {
        dailyData['waterIntake'] = (dailyData['waterIntake'] ?? 0) + amount;
      });

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .doc(formattedDate)
          .set({
            'waterIntake': FieldValue.increment(amount),
          }, SetOptions(merge: true));
    } catch (e) {
      _showErrorSnackbar('Failed to update water intake');
      setState(() {
        dailyData['waterIntake'] = (dailyData['waterIntake'] ?? 0) - amount;
      });
    }
  }

  void changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    fetchDailyData();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute? route = ModalRoute.of(context);
    if (route != null && route.isCurrent == false) {
      fetchDailyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Convert all to double with proper null handling
    double foodCalories =
        (dailyData['foodCalories'] as num?)?.toDouble() ?? 0.0;
    double exerciseCalories =
        (dailyData['exerciseCalories'] as num?)?.toDouble() ?? 0.0;
    double targetCalories =
        (dailyData['targetCalories'] as num?)?.toDouble() ?? 2000.0;
    double remainingCalories =
        (dailyData['remainingCalories'] as num?)?.toDouble() ?? targetCalories;
    double protein = (dailyData['protein'] as num?)?.toDouble() ?? 0.0;
    double fat = (dailyData['fat'] as num?)?.toDouble() ?? 0.0;
    double carbs = (dailyData['carbs'] as num?)?.toDouble() ?? 0.0;
    double waterIntake = (dailyData['waterIntake'] as num?)?.toDouble() ?? 0.0;
    double recommendedWater =
        (dailyData['recommendedWater'] as num?)?.toDouble() ?? 2000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily Logging",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 20),
              _buildCaloriesSection(
                targetCalories,
                exerciseCalories,
                foodCalories,
                remainingCalories,
              ),
              const SizedBox(height: 20),
              _buildNutrientSummary(protein, fat, carbs),
              const SizedBox(height: 20),
              _buildLoggingSection(
                "Exercise",
                "${exerciseCalories.toStringAsFixed(0)} kcal burned",
                "Log Exercise",
                Icons.directions_run,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseLoggingPage(),
                    ),
                  );
                },
              ),
              _buildWaterLoggingSection(waterIntake, recommendedWater),
              _buildMealLogging("Breakfast"),
              _buildMealLogging("Lunch"),
              _buildMealLogging("Dinner"),
              _buildMealLogging("Snack"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => changeDate(-1),
        ),
        Text(
          "${selectedDate.toLocal()}".split(' ')[0],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => changeDate(1),
        ),
      ],
    );
  }

  Widget _buildCaloriesSection(
    double target,
    double exercise,
    double food,
    double remaining,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Remaining Calories",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _formatDouble(target),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Target",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "+${_formatDouble(exercise)}",
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
              const SizedBox(width: 10),
              const Text(
                "Exercise",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "-${_formatDouble(food)}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Text(
                "Food",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _formatDouble(remaining),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: remaining >= 0 ? Colors.teal : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Remaining",
                style: TextStyle(
                  fontSize: 16,
                  color: remaining >= 0 ? Colors.grey : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildNutrientSummary(double protein, double fat, double carbs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daily Total",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNutrientBox(
              "Protein",
              "${_formatDouble(protein)}g",
              Colors.blue,
            ),
            _buildNutrientBox("Fat", "${_formatDouble(fat)}g", Colors.orange),
            _buildNutrientBox(
              "Carbs",
              "${_formatDouble(carbs)}g",
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealLogging(String mealType) {
    // Filter logs for this meal type
    final mealLogs =
        foodLogs
            .where(
              (log) =>
                  (log['mealType'] as String).toLowerCase() ==
                  mealType.toLowerCase(),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mealType,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child: Column(
            children: [
              if (mealLogs.isNotEmpty)
                ...mealLogs.map(
                  (log) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_getMealIcon(mealType), color: Colors.teal),
                    title: Text(log['description'] ?? 'No description'),
                    subtitle: Text(
                      "${(log['calories'] as num?)?.toStringAsFixed(0)} kcal • "
                      "${DateFormat.jm().format((log['timestamp'] as Timestamp).toDate())}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFoodLog(log['id']),
                    ),
                  ),
                ),
              if (mealLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "No logs yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodScanPage(mealType: mealType),
                    ),
                  ).then((_) => fetchFoodLogs());
                },
                icon: const Icon(Icons.add),
                label: const Text("Log Food"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoggingSection(
    String title,
    String value,
    String buttonText,
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 10),
              Text(value, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWaterLoggingSection(
    double waterIntake,
    double recommendedWater,
  ) {
    double progress = waterIntake / recommendedWater;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Water",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_drink, color: Colors.teal),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_formatDouble(waterIntake)}mL / ${_formatDouble(recommendedWater)}mL",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(progress * 100).toStringAsFixed(1)}% of daily goal",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWaterAddButton(250),
                  _buildWaterAddButton(500),
                  _buildWaterAddButton(1000),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWaterAddButton(int amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape:
            const StadiumBorder(), // Changed from CircleBorder to StadiumBorder
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => _addWater(amount),
      child: Text("+${amount}mL", style: const TextStyle(fontSize: 14)),
    );
  }

  Future<void> _deleteFoodLog(String logId) async {
    try {
      String userId =
          FirebaseAuth
              .instance
              .currentUser!
              .uid; // 1. First get the food log document to be deleted
      DocumentSnapshot logDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('food_logs')
              .doc(logId)
              .get();

      if (!logDoc.exists) {
        _showErrorSnackbar('Food log not found');
        return;
      }

      Map<String, dynamic> logData = logDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> nutrients = logData['nutrients'] ?? {};

      // 2. Delete the food log document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('food_logs')
          .doc(logId)
          .delete();

      // 3. Update daily_nutrients by decrementing values
      String logDate = logData['date']; // Get the date from the log
      DocumentReference dailyNutrientsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_nutrients')
          .doc(logDate);

      // Prepare update with decrement operations
      Map<String, dynamic> updates = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add decrement for each nutrient
      nutrients.forEach((key, value) {
        if (value is num) {
          updates[key] = FieldValue.increment(-value.toDouble());
        }
      });

      // Execute the update
      await dailyNutrientsRef.set(updates, SetOptions(merge: true));

      // 4. Refresh the UI
      await fetchFoodLogs();
      await fetchDailyData();

      _showErrorSnackbar('Food log deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to delete: ${e.toString()}');
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.fastfood;
      default:
        return Icons.restaurant;
    }
  }
}
