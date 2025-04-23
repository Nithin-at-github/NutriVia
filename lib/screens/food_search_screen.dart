import 'package:flutter/material.dart';
import 'package:nutrivia/services/food_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  _FoodSearchScreenState createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final FoodService foodService = FoodService();
  final TextEditingController _controller = TextEditingController();
  List<dynamic> foods = [];
  String userRegion = "";
  String? userDietPreference;
  List<String> userDietRestrictions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          userRegion = userDoc['country'];
          userDietPreference = userDoc['dietaryPreference']; // e.g., "low-carb"
          userDietRestrictions = List<String>.from(
            userDoc['dietaryRestrictions'],
          );
        });
      }
    }
  }

  void searchFood() async {
    if (userRegion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User region not available. Please complete profile."),
        ),
      );
      return;
    }

    final results = await foodService.fetchFoods(
      _controller.text,
      userRegion,
      userDietPreference,
      userDietRestrictions,
    );

    setState(() {
      foods = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Foods")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter food name",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchFood,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text("Region: $userRegion", style: TextStyle(fontSize: 16)),
            Text(
              "Diet: ${userDietPreference ?? 'None'}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Restrictions: ${userDietRestrictions.join(', ')}",
              style: TextStyle(fontSize: 16),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  final food = foods[index]['food'];
                  return ListTile(
                    title: Text(food['label']),
                    subtitle: Text(
                      "Calories: ${food['nutrients']['ENERC_KCAL']} kcal",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
