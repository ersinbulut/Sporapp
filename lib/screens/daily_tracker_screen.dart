import 'package:flutter/material.dart';
import 'package:sporapp/helpers/database_helper.dart';
import 'package:sporapp/models/workout.dart';
import 'package:sporapp/models/meal.dart';
import 'package:sporapp/services/step_count_service.dart';
import 'package:intl/intl.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({Key? key}) : super(key: key);

  @override
  _DailyTrackerScreenState createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  final _dbHelper = DatabaseHelper();
  final _stepCountService = StepCountService();
  DateTime _selectedDate = DateTime.now();
  List<Workout> _workouts = [];
  List<Meal> _meals = [];
  int _totalCaloriesBurned = 0;
  int _totalCaloriesConsumed = 0;
  int _netCalories = 0;
  int _stepCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final workouts = await _dbHelper.getWorkoutsByDate(_selectedDate);
    final meals = await _dbHelper.getMealsByDate(_selectedDate);
    final stepCount = await _stepCountService.getStepCountByDate(_selectedDate);
    final calorieSummary = await _dbHelper.getDailyCalorieSummary(_selectedDate);

    setState(() {
      _workouts = workouts;
      _meals = meals;
      _stepCount = stepCount;
      _totalCaloriesBurned = calorieSummary['burned']!;
      _totalCaloriesConsumed = calorieSummary['consumed']!;
      _netCalories = calorieSummary['net']!;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${DateFormat('d MMMM yyyy').format(_selectedDate)} Özeti',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCalorieInfo(
                                'Alınan Kalori',
                                _totalCaloriesConsumed,
                                Icons.add_circle,
                                Colors.green,
                              ),
                              _buildCalorieInfo(
                                'Yakılan Kalori',
                                _totalCaloriesBurned,
                                Icons.remove_circle,
                                Colors.red,
                              ),
                              _buildCalorieInfo(
                                'Net Kalori',
                                _netCalories,
                                Icons.balance,
                                Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_walk,
                                size: 32,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_stepCount adım',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _stepCount / 10000,
                              minHeight: 12,
                              backgroundColor: Colors.blue.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hedef: 10,000 adım',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Egzersizler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_workouts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Bu tarihte egzersiz kaydı bulunmuyor'),
                      ),
                    )
                  else
                    ..._workouts.map((workout) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(workout.name),
                            subtitle: Text('${workout.duration} dakika'),
                            trailing: Text(
                              '-${workout.caloriesBurned} kcal',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  const Text(
                    'Yemekler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_meals.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Bu tarihte yemek kaydı bulunmuyor'),
                      ),
                    )
                  else
                    ..._meals.map((meal) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant),
                            title: Text(meal.name),
                            trailing: Text(
                              '+${meal.calories} kcal',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildCalorieInfo(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$value kcal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
} 