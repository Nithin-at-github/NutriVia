import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivia/screens/main_navigation_screen.dart';
import 'package:nutrivia/screens/signup_step1.dart';
import 'package:nutrivia/services/service_locator.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupServiceLocator();
  runApp(NutriViaApp());
}

class NutriViaApp extends StatelessWidget {
  const NutriViaApp({super.key});

  Future<Widget> _getInitialScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return IntroScreen(); // No user signed in
    }

    // Fetch user details from Firestore
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (userDoc.exists && userDoc['profileCompleted'] == true) {
      return MainNavigationScreen(); // Profile completed
    } else {
      return SignupStep1(); // Profile incomplete
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriVia',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ); // Show loading screen
          }
          return snapshot.data ?? IntroScreen();
        },
      ),
    );
  }
}
