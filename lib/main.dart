import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sporapp/screens/add_workout_screen.dart';
import 'package:sporapp/screens/add_meal_screen.dart';
import 'package:sporapp/screens/home_screen.dart';
import 'package:sporapp/screens/onboarding_screen.dart';
import 'package:sporapp/screens/daily_tracker_screen.dart';
import 'package:sporapp/screens/book_list_screen.dart';
import 'package:sporapp/screens/step_counter_screen.dart';
import 'package:sporapp/helpers/database_helper.dart';
import 'package:sporapp/models/workout.dart';
import 'package:sporapp/models/meal.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spor ve Beslenme Takibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final dbHelper = DatabaseHelper();
    final userGoals = await dbHelper.getUserGoals();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => userGoals == null
            ? OnboardingScreen()
            : MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Spor ve Beslenme Takibi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StepCounterScreen(),
    const DailyTrackerScreen(),
    const BookListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Adım Sayacı',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Günlük Takip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Kitaplar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper();
  List<Workout> _workouts = [];
  List<Meal> _meals = [];
  int _totalCaloriesBurned = 0;
  int _totalCaloriesConsumed = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now();
    final workouts = await _dbHelper.getWorkoutsByDate(today);
    final meals = await _dbHelper.getMealsByDate(today);

    setState(() {
      _workouts = workouts;
      _meals = meals;
      _totalCaloriesBurned = workouts.fold(0, (sum, workout) => sum + workout.caloriesBurned);
      _totalCaloriesConsumed = meals.fold(0, (sum, meal) => sum + meal.calories);
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Egzersiz Ekle'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddWorkoutScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadTodayData();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Yemek Ekle'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMealScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadTodayData();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteWorkout(Workout workout) async {
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
      try {
        await _dbHelper.deleteWorkout(workout.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Egzersiz başarıyla silindi')),
          );
          _loadTodayData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata oluştu: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
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
      try {
        await _dbHelper.deleteMeal(meal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yemek başarıyla silindi')),
          );
          _loadTodayData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata oluştu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Spor Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Günlük Kalori Özeti',
                      style: TextStyle(
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
                          _totalCaloriesConsumed - _totalCaloriesBurned,
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '-${workout.caloriesBurned} kcal',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWorkout(workout),
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
                    child: ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(meal.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${meal.calories} kcal',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMeal(meal),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalorieInfo(String title, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
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
