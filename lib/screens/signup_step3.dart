import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'signup_step4.dart';

class SignupStep3 extends StatefulWidget {
  final String name;
  final int age;
  final String? gender;
  final double weight;
  final double height;
  final double bmi;
  final String bmiStatus;

  const SignupStep3({
    super.key,
    required this.name,
    required this.age,
    this.gender,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bmiStatus,
  });

  @override
  _SignupStep3State createState() => _SignupStep3State();
}

class _SignupStep3State extends State<SignupStep3> {
  String? country;
  String? state;
  String? city;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text("Step 3: Location"),
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
                "Step 3 of 4",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 20),
              SelectState(
                onCountryChanged: (value) {
                  setState(() {
                    country = value;
                  });
                },
                onStateChanged: (value) {
                  setState(() {
                    state = value;
                  });
                },
                onCityChanged: (value) {
                  setState(() {
                    city = value;
                  });
                },
              ),
              SizedBox(height: 10),
              if (country != null && state != null && city != null)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Selected: $city, $state, $country",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  ),
                  child: Text("Next",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: () {
                    if (country == null || state == null || city == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please select your location")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupStep4(
                          name: widget.name,
                          age: widget.age,
                          gender: widget.gender,
                          weight: widget.weight,
                          height: widget.height,
                          bmi: widget.bmi,
                          bmiStatus: widget.bmiStatus,
                          country: country!,
                          state: state!,
                          city: city!,
                        ),
                      ),
                    );
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
