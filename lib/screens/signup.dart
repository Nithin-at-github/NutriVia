import 'package:flutter/material.dart';
import 'package:nutrivia/screens/signin.dart';
import 'package:nutrivia/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrivia/screens/signup_step1.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = await _authService.signUpWithEmail(
            _emailController.text, _passwordController.text);
        if (user != null) {
          print("User signed up successfully: ${user.email}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignupStep1()),
          );
        } else {
          print("Signup failed: User is null");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Signup failed! Try again.")));
        }
      } catch (e) {
        print("Firebase Signup Error: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _signUpWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      print("Google Sign-Up successful: ${user.email}");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SignupStep1()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google Sign-In failed")));
    }
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
                Text("Create an Account",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: "Email", border: OutlineInputBorder()),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your email" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: "Password", border: OutlineInputBorder()),
                  validator: (value) =>
                      value!.length < 6 ? "Enter a valid password" : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text("Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signUpWithGoogle,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/google.png", height: 24),
                      SizedBox(width: 10),
                      Text("Sign Up with Google",
                          style: TextStyle(fontSize: 18, color: Colors.teal)),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Navigate to Sign-In
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignInScreen()));
                  },
                  child: Text("Already have an account? Sign In",
                      style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
