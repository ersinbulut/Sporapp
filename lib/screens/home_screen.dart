import 'package:flutter/material.dart';
import 'package:sporapp/helpers/database_helper.dart';
import 'package:sporapp/models/workout.dart';
import 'package:sporapp/models/meal.dart';
import 'package:sporapp/screens/add_workout_screen.dart';
import 'package:sporapp/screens/add_meal_screen.dart';
import 'package:sporapp/widgets/main_navigation.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import '../services/step_count_service.dart';
import '../models/step_count.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper();
  final StepCountService _stepCountService = StepCountService();
  List<Workout> _workouts = [];
  List<Meal> _meals = [];
  int _totalCaloriesBurned = 0;
  int _totalCaloriesConsumed = 0;
  int _netCalories = 0;
  DateTime _selectedDate = DateTime.now();
  List<FlSpot> _calorieSpots = [];
  double _maxCalories = 0;
  int _currentSteps = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeStepCount();
  }

  Future<void> _loadData() async {
    final workouts = await _dbHelper.getWorkoutsByDate(_selectedDate);
    final meals = await _dbHelper.getMealsByDate(_selectedDate);
    final calorieSummary = await _dbHelper.getDailyCalorieSummary(_selectedDate);

    // Son 7 günün verilerini al
    List<FlSpot> spots = [];
    double maxCal = 0;
    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      final summary = await _dbHelper.getDailyCalorieSummary(date);
      spots.add(FlSpot(i.toDouble(), summary['consumed']!.toDouble()));
      if (summary['consumed']! > maxCal) maxCal = summary['consumed']!.toDouble();
    }

    setState(() {
      _workouts = workouts;
      _meals = meals;
      _totalCaloriesBurned = calorieSummary['burned']!;
      _totalCaloriesConsumed = calorieSummary['consumed']!;
      _netCalories = calorieSummary['net']!;
      _calorieSpots = spots;
      _maxCalories = maxCal;
    });
  }

  void _initializeStepCount() {
    _stepCountService.stepCountStream.listen((StepCount stepCount) {
      setState(() {
        _currentSteps = stepCount.steps;
      });
    });
  }

  Widget _buildCalorieChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: _maxCalories * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: _calorieSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildStepCounterScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Günlük Adım Sayısı',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Icon(
                        Icons.directions_walk,
                        size: 32,
                        color: Colors.blue.shade900,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_currentSteps',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _currentSteps / 10000,
                      minHeight: 12,
                      backgroundColor: Colors.blue.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hedef: 10,000 adım',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım Sayacı Hakkında',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.info_outline,
                    'Günlük 10,000 adım hedefi, sağlıklı bir yaşam için önerilen minimum adım sayısıdır.',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.trending_up,
                    'Düzenli yürüyüş, kalp sağlığını iyileştirir ve kilo kontrolüne yardımcı olur.',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.timer,
                    'Adım sayacı, günlük aktivite seviyenizi takip etmenize yardımcı olur.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: _buildSelectedScreen(),
      bottomNavigationBar: MainNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Adım Sayacı';
      case 2:
        return 'Egzersizler';
      case 3:
        return 'Yemekler';
      default:
        return 'Ana Sayfa';
    }
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildStepCounterScreen();
      case 2:
        return _buildWorkoutsScreen();
      case 3:
        return _buildMealsScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
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
              ),
              _buildStepCounter(),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Haftalık Kalori Takibi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildCalorieChart(),
              ],
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
            ..._workouts.map((workout) => _buildWorkoutCard(workout)),
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
            ..._meals.map((meal) => _buildMealCard(meal)),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return Card(
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
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Card(
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
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                        size: 40,
                      ),
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

  void _showAddOptions(BuildContext context) {
    // Implement the logic to show the add options dialog
  }

  Widget _buildStepCounter() {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adım Sayısı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Icon(
                    Icons.directions_walk,
                    size: 24,
                    color: Colors.blue.shade900,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_currentSteps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _currentSteps / 10000,
                  minHeight: 8,
                  backgroundColor: Colors.blue.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hedef: 10,000',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsScreen() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Egzersizler',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_workouts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Henüz egzersiz kaydı bulunmuyor'),
              ),
            )
          else
            ..._workouts.map((workout) => _buildWorkoutCard(workout)),
        ],
      ),
    );
  }

  Widget _buildMealsScreen() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Yemekler',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_meals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Henüz yemek kaydı bulunmuyor'),
              ),
            )
          else
            ..._meals.map((meal) => _buildMealCard(meal)),
        ],
      ),
    );
  }
} 