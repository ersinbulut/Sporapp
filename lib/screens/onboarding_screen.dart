import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporapp/helpers/database_helper.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calorieController = TextEditingController();
  final _workoutController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void dispose() {
    _calorieController.dispose();
    _workoutController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _dbHelper.saveUserGoals(
        dailyCalorieGoal: int.parse(_calorieController.text),
        dailyWorkoutMinutes: int.parse(_workoutController.text),
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Hedeflerinizi Belirleyin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Günlük kalori hedefinizi ve spor sürenizi belirleyerek başlayın.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _calorieController,
                  decoration: const InputDecoration(
                    labelText: 'Günlük Kalori Hedefi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_fire_department),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen kalori hedefinizi girin';
                    }
                    final calories = int.tryParse(value);
                    if (calories == null || calories <= 0) {
                      return 'Geçerli bir kalori değeri girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _workoutController,
                  decoration: const InputDecoration(
                    labelText: 'Günlük Spor Süresi (Dakika)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen spor sürenizi girin';
                    }
                    final minutes = int.tryParse(value);
                    if (minutes == null || minutes <= 0) {
                      return 'Geçerli bir süre girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoals,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Başla',
                          style: TextStyle(fontSize: 18),
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