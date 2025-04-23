import 'package:flutter/material.dart';
import 'signup_step2.dart';

class SignupStep1 extends StatefulWidget {
  const SignupStep1({super.key});

  @override
  _SignupStep1State createState() => _SignupStep1State();
}

class _SignupStep1State extends State<SignupStep1> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? gender;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      backgroundColor: Colors.teal.shade50,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Step 1 of 4",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: "Full Name", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Enter your full name" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Age", border: OutlineInputBorder()),
                validator: (value) {
                  if (value!.isEmpty) return "Enter your age";
                  int? age = int.tryParse(value);
                  if (age == null || age <= 0) return "Enter a valid age";
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(
                    labelText: "Gender", border: OutlineInputBorder()),
                items: ["Male", "Female", "Other"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    gender = newValue;
                  });
                },
                validator: (value) => value == null ? "Select a gender" : null,
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    backgroundColor: Colors.teal,
                  ),
                  child: Text("Next",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupStep2(
                            name: nameController.text,
                            age: int.parse(ageController.text),
                            gender: gender!,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
