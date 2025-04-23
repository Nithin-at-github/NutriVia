import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutrivia/screens/onboarding_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrivia/services/nutrition_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double bmi = 0.0;
  double bmr = 0.0;
  double tdee = 0.0;
  Map<String, dynamic> dailyNutrients = {};
  Map<String, dynamic> recommendedNutrients = {};
  String selectedDate = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now()); // Default to today
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  ); // Start of the current week

  @override
  void initState() {
    super.initState();
    _updateAndFetchNutritionData();
  }

  Future<void> _updateAndFetchNutritionData() async {
    if (userId == null) {
      print("User not logged in");
      return;
    }
    NutritionService nutritionService = NutritionService();
    await nutritionService.calculateAndStoreNutrition(userId!);
    _fetchNutritionDataForDate(selectedDate);
  }

  Future<void> _fetchNutritionDataForDate(String date) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    DocumentSnapshot dailyDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('daily_nutrients')
            .doc(date)
            .get();
    setState(() {
      bmi = (userDoc['bmi'] ?? 0.0).toDouble();
      bmr = (userDoc['bmr'] ?? 0.0).toDouble();
      tdee = (userDoc['tdee'] ?? 0.0).toDouble();
      dailyNutrients =
          dailyDoc.exists ? dailyDoc.data() as Map<String, dynamic> : {};
      recommendedNutrients = userDoc['recommendedNutrients'] ?? {};
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/NutriVia.png', // Path to your image
              width: 40, // Adjust the width as needed
              height: 40, // Adjust the height as needed
            ),
            SizedBox(width: 8), // Add spacing between the image and text
            Text(
              'NutriVia',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Logout"),
                    content: Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IntroScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendar(), // Add the scrollable calendar
              SizedBox(height: 20),
              _buildBodyMetrics(),
              SizedBox(height: 20),
              _buildSectionTitle(
                'Nutrient Overview',
                Icons.restaurant_menu,
                Colors.green,
              ),
              _buildNutrientOverview(),
              SizedBox(height: 20),
              _buildSectionTitle('Heart Health', Icons.favorite, Colors.red),
              _buildCustomSection(
                [
                  'Cholesterol',
                  'Omega-3',
                  'Fiber',
                  'Water',
                  'Saturated Fat',
                  'Sodium',
                ],
                Colors.red,
                Colors.red[50]!,
              ),
              SizedBox(height: 20),
              _buildSectionTitle(
                'Controlled Consumption',
                Icons.speed,
                Colors.teal,
              ),
              _buildCustomSection(
                ['Sugar', 'Trans Fat', 'Caffeine', 'Alcohol'],
                Colors.teal,
                Colors.teal[50]!,
              ),
              SizedBox(height: 20),
              _buildSectionTitle(
                'Key Vitamins',
                Icons.local_pharmacy,
                Colors.pink,
              ),
              _buildCustomSection(
                [
                  'Vitamin D',
                  'Vitamin B12',
                  'Vitamin C',
                  'Vitamin B9',
                  'Vitamin A',
                ],
                Colors.pink,
                Colors.pink[50]!,
              ),
              SizedBox(height: 20),
              _buildSectionTitle(
                'Vital Minerals',
                Icons.diamond,
                Colors.indigo,
              ),
              _buildCustomSection(
                ['Iron', 'Calcium', 'Magnesium', 'Zinc', 'Potassium'],
                Colors.indigo,
                Colors.indigo[50]!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Row(
      children: [
        // Left Arrow
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goToPreviousWeek,
          padding: EdgeInsets.zero, // Remove default padding
          constraints: BoxConstraints(), // Remove default constraints
        ),
        // Calendar
        Expanded(
          child: SizedBox(
            height: 60, // Reduced height to fit the screen
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7, // Display 7 days
              itemBuilder: (context, index) {
                DateTime date = _currentWeekStart.add(Duration(days: index));
                String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                bool isSelected = formattedDate == selectedDate;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = formattedDate;
                    });
                    _fetchNutritionDataForDate(
                      selectedDate,
                    ); // Fetch data for the selected date
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date), // Day (Sun, Mon, etc.)
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(date), // Date (9, 10, etc.)
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _goToNextWeek,
          padding: EdgeInsets.zero, // Remove default padding
          constraints: BoxConstraints(), // Remove default constraints
        ),
      ],
    );
  }

  Widget _buildBodyMetrics() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap:
                () => _showDescription(
                  context,
                  "BMI (Body Mass Index)",
                  "BMI is a measure of body fat based on height and weight.\n\n"
                      "BMI Ranges:\n"
                      "- Underweight: Less than 18.5\n"
                      "- Normal weight: 18.5 - 24.9\n"
                      "- Overweight: 25 - 29.9\n"
                      "- Obesity: 30 or greater\n\n"
                      "Note: BMI is a general indicator and may not account for muscle mass or body composition.",
                ),
            child: _buildMetricCard('BMI', bmi.toStringAsFixed(2), 'kg/m²'),
          ),
          GestureDetector(
            onTap:
                () => _showDescription(
                  context,
                  "BMR (Basal Metabolic Rate)",
                  "BMR is the number of calories your body burns at rest to maintain basic functions like breathing, circulation, and cell production.\n\n"
                      "Factors affecting BMR:\n"
                      "- Age: BMR decreases with age.\n"
                      "- Gender: Men typically have a higher BMR than women.\n"
                      "- Muscle Mass: More muscle increases BMR.\n"
                      "- Body Size: Larger bodies have a higher BMR.\n\n"
                      "BMR is used to estimate your daily calorie needs.",
                ),
            child: _buildMetricCard('BMR', bmr.toStringAsFixed(1), 'kcal/day'),
          ),
          GestureDetector(
            onTap:
                () => _showDescription(
                  context,
                  "TDEE (Total Daily Energy Expenditure)",
                  "TDEE is the total number of calories you burn in a day, including:\n"
                      "- Basal Metabolic Rate (BMR)\n"
                      "- Physical Activity\n"
                      "- Thermic Effect of Food (calories burned during digestion)\n\n"
                      "TDEE is used to determine your daily calorie needs for:\n"
                      "- Weight Loss: Consume fewer calories than your TDEE.\n"
                      "- Weight Maintenance: Consume calories equal to your TDEE.\n"
                      "- Weight Gain: Consume more calories than your TDEE.\n\n"
                      "Your TDEE is calculated based on your activity level and BMR.",
                ),
            child: _buildMetricCard(
              'TDEE',
              tdee.toStringAsFixed(1),
              'kcal/day',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 5),
            Text('$value $unit', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientOverview() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) {
      return Center(child: Text("User not logged in"));
    }

    // Define dailyNutrientsCollection inside the function
    CollectionReference dailyNutrientsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_nutrients');

    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: Future.wait([
        dailyNutrientsCollection
            .doc(selectedDate)
            .get()
            .then(
              (doc) => doc as DocumentSnapshot<Map<String, dynamic>>,
            ), // Fetch consumed values for the selected date
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get()
            .then((doc) => doc), // Fetch recommended values
      ]),
      builder: (
        context,
        AsyncSnapshot<List<DocumentSnapshot<Map<String, dynamic>>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading data"));
        }

        if (!snapshot.hasData ||
            snapshot.data!.length < 2 ||
            !snapshot.data![1].exists) {
          return Center(child: Text("No data available"));
        }

        // Extract data
        Map<String, dynamic> consumedData = snapshot.data![0].data() ?? {};
        Map<String, dynamic> userData = snapshot.data![1].data() ?? {};

        // Extract recommended values from user document
        Map<String, double> recommendedValues = {
          'Calories': (userData['dailyCalories'] ?? 2000).toDouble(),
          'Protein': (userData['dailyProtein'] ?? 50).toDouble(),
          'Fat': (userData['dailyFat'] ?? 70).toDouble(),
          'Carbs': (userData['dailyCarbs'] ?? 300).toDouble(),
        };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: Row(
            children:
                recommendedValues.keys.map((nutrient) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ), // Add spacing
                    child: _buildCircularIndicator(
                      nutrient,
                      (consumedData[nutrient] ?? 0)
                          .toDouble(), // Consumed amount
                      recommendedValues[nutrient]!, // Recommended amount
                      Colors.green,
                      Colors.green[50]!,
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCustomSection(List<String> items, Color color, Color bgcolor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Row(
        children:
            items.map((item) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0), // Add spacing
                child: _buildCircularIndicator(
                  item,
                  dailyNutrients[item]?.toDouble() ?? 0,
                  recommendedNutrients[item]?.toDouble() ?? 100,
                  color,
                  bgcolor,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCircularIndicator(
    String label,
    double current,
    double max,
    Color color,
    Color bgcolor,
  ) {
    // Define units based on nutrient type
    Map<String, String> units = {
      'Calories': 'kcal',
      'Protein': 'g',
      'Fat': 'g',
      'Carbs': 'g',
      'Cholesterol': 'mg',
      'Omega-3': 'g',
      'Fiber': 'g',
      'Water': 'L',
      'Saturated Fat': 'g',
      'Sodium': 'mg',
      'Sugar': 'g',
      'Trans Fat': 'g',
      'Caffeine': 'mg',
      'Alcohol': 'g',
      'Vitamin D': 'mcg',
      'Vitamin B12': 'mcg',
      'Vitamin C': 'mg',
      'Vitamin B9': 'mcg',
      'Vitamin A': 'mcg',
      'Iron': 'mg',
      'Calcium': 'mg',
      'Magnesium': 'mg',
      'Zinc': 'mg',
      'Potassium': 'mg',
    };

    String unit = units[label] ?? ''; // Get unit or empty if not found

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 42.0,
          lineWidth: 4.0,
          percent: (current / max).clamp(0.0, 1.0),
          center: Text(
            '${current.toStringAsFixed(2)} \n/ $max $unit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          progressColor: color,
          backgroundColor: bgcolor,
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.0), // Adds spacing between icon and title
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDescription(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            // Wrap the Column in a SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use min to fit the content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(description, style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close", style: TextStyle(color: Colors.teal)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
