import 'package:flutter/material.dart';
import 'package:sporapp/helpers/database_helper.dart';
import 'package:sporapp/models/workout.dart';
import 'package:sporapp/models/meal.dart';
import 'package:sporapp/screens/add_workout_screen.dart';
import 'package:sporapp/screens/add_meal_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper();
  List<Workout> _workouts = [];
  List<Meal> _meals = [];
  int _totalCaloriesBurned = 0;
  int _totalCaloriesConsumed = 0;
  int _netCalories = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workouts = await _dbHelper.getWorkoutsByDate(_selectedDate);
    final meals = await _dbHelper.getMealsByDate(_selectedDate);
    final calorieSummary = await _dbHelper.getDailyCalorieSummary(_selectedDate);

    setState(() {
      _workouts = workouts;
      _meals = meals;
      _totalCaloriesBurned = calorieSummary['burned']!;
      _totalCaloriesConsumed = calorieSummary['consumed']!;
      _netCalories = calorieSummary['net']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
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
                      '${_formatDate(_selectedDate)} Kalori Özeti',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bugünkü Egzersizler',
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
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '-${workout.caloriesBurned} kcal',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            tooltip: 'Güncelle',
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddWorkoutScreen(workout: workout),
                                ),
                              );
                              if (result == true) {
                                await _loadData();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            tooltip: 'Sil',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Egzersizi Sil'),
                                  content: Text('${workout.name} egzersizini silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await _dbHelper.deleteWorkout(workout.id);
                                await _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 24),
            const Text(
              'Bugünkü Yemekler',
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: meal.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(meal.imagePath!),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Resim yükleme hatası: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 40,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.restaurant,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${meal.calories} kalori',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                tooltip: 'Güncelle',
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddMealScreen(meal: meal),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                tooltip: 'Sil',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Yemeği Sil'),
                                      content: Text('${meal.name} yemeğini silmek istediğinize emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await _dbHelper.deleteMeal(meal.id);
                                    await _loadData();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
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
        Icon(
          icon,
          color: color,
          size: 40,
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 