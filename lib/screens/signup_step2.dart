import 'package:flutter/material.dart';
import 'signup_step3.dart';

class SignupStep2 extends StatefulWidget {
  final String name;
  final int age;
  final String? gender;

  const SignupStep2(
      {super.key, required this.name, required this.age, this.gender});

  @override
  _SignupStep2State createState() => _SignupStep2State();
}

class _SignupStep2State extends State<SignupStep2> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  double bmi = 0;
  String bmiStatus = "";

  final _formKey = GlobalKey<FormState>();

  void calculateBMI() {
    double height = double.tryParse(heightController.text) ?? 0;
    double weight = double.tryParse(weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      double heightInMeters = height / 100;
      bmi = weight / (heightInMeters * heightInMeters);

      if (bmi < 18.5) {
        bmiStatus = "Underweight";
      } else if (bmi < 24.9) {
        bmiStatus = "Normal";
      } else if (bmi < 29.9) {
        bmiStatus = "Overweight";
      } else {
        bmiStatus = "Obese";
      }
    } else {
      bmi = 0;
      bmiStatus = "";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text("Step 2: Height & Weight"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Step 2 of 4",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Height (cm)", border: OutlineInputBorder()),
                onChanged: (value) => calculateBMI(),
                validator: (value) {
                  if (value!.isEmpty) return "Enter your height";
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return "Enter a valid height";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Weight (kg)", border: OutlineInputBorder()),
                onChanged: (value) => calculateBMI(),
                validator: (value) {
                  if (value!.isEmpty) return "Enter your weight";
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return "Enter a valid weight";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                "BMI: ${bmi > 0 ? bmi.toStringAsFixed(1) : "--"} ${bmiStatus.isNotEmpty ? "($bmiStatus)" : ""}",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  ),
                  child: Text("Next",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupStep3(
                            name: widget.name,
                            age: widget.age,
                            gender: widget.gender,
                            height: double.parse(heightController.text),
                            weight: double.parse(weightController.text),
                            bmi: bmi,
                            bmiStatus: bmiStatus,
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
