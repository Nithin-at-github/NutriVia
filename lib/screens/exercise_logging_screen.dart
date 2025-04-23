import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExerciseLoggingPage extends StatefulWidget {
  const ExerciseLoggingPage({super.key});

  @override
  _ExerciseLoggingPageState createState() => _ExerciseLoggingPageState();
}

class _ExerciseLoggingPageState extends State<ExerciseLoggingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double? userWeightKg; // Nullable until fetched
  bool isLoading = true;

  // Exercise database with intensity options
  final List<Exercise> allExercises = [
    Exercise(
      name: 'Walking',
      icon: Icons.directions_walk,
      intensityOptions: {
        'Slow (2.8-3.2 km/h)': 2.9,
        'Brisk (4.8-5.6 km/h)': 3.5,
        'Power walking': 5.0,
        'Hiking uphill': 6.0,
      },
    ),
    Exercise(
      name: 'Running',
      icon: Icons.directions_run,
      intensityOptions: {
        'Jogging (6.4 km/h)': 7.0,
        'Moderate (8 km/h)': 8.0,
        'Fast (9.7 km/h)': 9.8,
        'Sprinting': 12.0,
      },
    ),
    Exercise(
      name: 'Cycling',
      icon: Icons.directions_bike,
      intensityOptions: {
        'Leisurely (<16 km/h)': 4.0,
        'Moderate (16-19 km/h)': 6.0,
        'Vigorous (20-23 km/h)': 8.0,
        'Racing (>24 km/h)': 10.0,
      },
    ),
    // Add more exercises...
  ];

  List<Exercise> filteredExercises = [];
  List<ExerciseLog> loggedExercises = [];
  double totalCalories = 0;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    filteredExercises = allExercises;
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        setState(() {
          userWeightKg = (userData['weight'] as num).toDouble();
          isLoading = false;
        });
        _loadLoggedExercises();
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please set your weight in profile settings')),
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load user data')));
    }
  }

  Future<void> _loadLoggedExercises() async {
    if (userWeightKg == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final logDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('exercise_logs')
              .doc(formattedDate)
              .get();

      if (logDoc.exists && logDoc.data() != null) {
        setState(() {
          loggedExercises =
              (logDoc.data()!['exercises'] as List)
                  .map((e) => ExerciseLog.fromMap(e))
                  .toList();
          totalCalories = logDoc.data()!['totalCalories'] as double;
        });
      }
    } catch (e) {
      print('Error loading exercise logs: $e');
    }
  }

  Future<void> _saveExerciseLog() async {
    if (userWeightKg == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('exercise_logs')
          .doc(formattedDate)
          .set({
            'exercises': loggedExercises.map((e) => e.toMap()).toList(),
            'totalCalories': totalCalories,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save exercise log')));
    }
  }

  double _calculateCalories(double metValue, int durationMinutes) {
    if (userWeightKg == null) return 0;
    return metValue * userWeightKg! * (durationMinutes / 60);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userWeightKg == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Log Exercise',
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Weight data not found'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text('Set Weight in Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log Exercise',
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              _saveExerciseLog();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search),
                border: UnderlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filteredExercises =
                      allExercises
                          .where(
                            (exercise) => exercise.name.toLowerCase().contains(
                              value.toLowerCase(),
                            ),
                          )
                          .toList();
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...filteredExercises.map(
                  (exercise) => ExerciseCard(
                    exercise: exercise,
                    userWeightKg: userWeightKg!,
                    onLog: (intensity, duration) {
                      _logExercise(exercise, intensity, duration);
                    },
                  ),
                ),
                if (loggedExercises.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Logged Exercises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...loggedExercises.map(
                    (log) => LoggedExerciseTile(
                      log: log,
                      onDelete: () => _removeExercise(log),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today ${DateFormat('h:mm a').format(DateTime.now())}',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'Total: ${totalCalories.toStringAsFixed(1)} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logExercise(Exercise exercise, String intensity, int duration) {
    final metValue = exercise.intensityOptions[intensity]!;
    final calories = _calculateCalories(metValue, duration);

    setState(() {
      loggedExercises.add(
        ExerciseLog(
          name: exercise.name,
          icon: exercise.icon,
          calories: calories,
          intensity: intensity,
          metValue: metValue,
          duration: duration,
          timestamp: DateTime.now(),
        ),
      );
      totalCalories += calories;
    });
  }

  void _removeExercise(ExerciseLog log) {
    setState(() {
      loggedExercises.remove(log);
      totalCalories -= log.calories;
    });
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final double userWeightKg;
  final Function(String, int) onLog;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.userWeightKg,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showLogDialog(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(exercise.icon, size: 30, color: Colors.teal),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${exercise.intensityOptions.length} intensity levels',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    String selectedIntensity = exercise.intensityOptions.keys.first;
    int selectedDuration = 30;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final currentMet = exercise.intensityOptions[selectedIntensity]!;
              final currentCalories =
                  currentMet * userWeightKg * (selectedDuration / 60);

              return AlertDialog(
                title: Row(
                  children: [
                    Icon(exercise.icon, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Log ${exercise.name}'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedIntensity,
                      items:
                          exercise.intensityOptions.keys
                              .map(
                                (intensity) => DropdownMenuItem(
                                  value: intensity,
                                  child: Text(intensity),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => selectedIntensity = value!);
                      },
                      decoration: InputDecoration(labelText: 'Intensity'),
                    ),
                    SizedBox(height: 20),
                    Text('Duration: $selectedDuration minutes'),
                    Slider(
                      value: selectedDuration.toDouble(),
                      min: 1,
                      max: 180,
                      divisions: 179,
                      label: '$selectedDuration min',
                      onChanged: (value) {
                        setState(() => selectedDuration = value.round());
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Estimated calories: ${currentCalories.toStringAsFixed(1)} kcal',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Based on your weight: ${userWeightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onLog(selectedIntensity, selectedDuration);
                      Navigator.pop(context);
                    },
                    child: Text('Log Exercise'),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class LoggedExerciseTile extends StatelessWidget {
  final ExerciseLog log;
  final VoidCallback onDelete;

  const LoggedExerciseTile({
    super.key,
    required this.log,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(log.icon, color: Colors.teal),
        title: Text(log.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.intensity),
            Text(
              '${log.duration} min • ${DateFormat('h:mm a').format(log.timestamp)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${log.calories.toStringAsFixed(1)} kcal',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class Exercise {
  final String name;
  final IconData icon;
  final Map<String, double> intensityOptions;

  Exercise({
    required this.name,
    required this.icon,
    Map<String, double>? intensityOptions, // Make parameter optional
  }) : intensityOptions =
           intensityOptions ?? {}; // Provide empty map as default
}

class ExerciseLog {
  final String name;
  final IconData icon;
  final double calories;
  final String intensity;
  final double metValue;
  final int duration;
  final DateTime timestamp;

  ExerciseLog({
    required this.name,
    required this.icon,
    required this.calories,
    required this.intensity,
    required this.metValue,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'calories': calories,
      'intensity': intensity,
      'metValue': metValue,
      'duration': duration,
      'timestamp': timestamp,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      name: map['name'],
      icon: IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons'),
      calories: map['calories'],
      intensity: map['intensity'],
      metValue: map['metValue'],
      duration: map['duration'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
