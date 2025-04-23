import 'package:flutter/material.dart';
import 'package:nutrivia/screens/main_navigation_screen.dart';
// import 'package:nutrivia/screens/meal_plan_screen.dart';
import 'package:nutrivia/screens/signup.dart';
import 'package:nutrivia/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivia/screens/signup_step1.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        User? user = await _authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        if (user != null) {
          _checkProfileCompletion(user);
        } else {
          _showError("Invalid credentials. Try again!");
        }
      } catch (e) {
        _showError("Error: ${e.toString()}");
      }
      setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      _checkProfileCompletion(user);
    } else {
      _showError("Google Sign-In failed");
    }
    setState(() => _isLoading = false);
  }

  void _checkProfileCompletion(User user) async {
    DocumentSnapshot profile =
        await _firestore.collection("users").doc(user.uid).get();
    if (profile.exists && profile["profileCompleted"] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigationScreen()),
      );
      //   context,
      //   MaterialPageRoute(builder: (context) => MealPlanScreen()),
      // );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupStep1()),
      );
    }
  }

  void _forgotPassword() async {
    if (_emailController.text.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text,
        );
        _showMessage("Password reset email sent!");
      } catch (e) {
        _showError("Error: ${e.toString()}");
      }
    } else {
      _showError("Enter your email to reset password.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter your email" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.length < 6 ? "Enter a valid password" : null,
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: Text(
                        "Sign In",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                SizedBox(height: 10),
                _isLoading
                    ? SizedBox.shrink()
                    : ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset("assets/google.png", height: 24),
                          SizedBox(width: 10),
                          Text(
                            "Sign In with Google",
                            style: TextStyle(fontSize: 18, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.teal),
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
