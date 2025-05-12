import 'package:flutter/material.dart';
import '../services/step_count_service.dart';
import '../models/step_count.dart';
import 'package:intl/intl.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({Key? key}) : super(key: key);

  @override
  _StepCounterScreenState createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  final StepCountService _stepCountService = StepCountService();
  int _currentSteps = 0;
  DateTime _selectedDate = DateTime.now();
  List<StepCount> _stepHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStepCount();
    _loadStepHistory();
  }

  void _initializeStepCount() {
    _stepCountService.stepCountStream.listen((StepCount stepCount) {
      setState(() {
        _currentSteps = stepCount.steps;
      });
    });
  }

  Future<void> _loadStepHistory() async {
    setState(() {
      _isLoading = true;
    });

    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    final history = await _stepCountService.getStepCountHistory(startDate, endDate);
    
    setState(() {
      _stepHistory = history;
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
      _loadStepHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adım Sayacı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat('MMMM yyyy').format(_selectedDate)} Adım Geçmişi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadStepHistory,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_stepHistory.isEmpty)
                      const Center(
                        child: Text('Bu ay için adım kaydı bulunmuyor'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stepHistory.length,
                        itemBuilder: (context, index) {
                          final stepCount = _stepHistory[index];
                          return ListTile(
                            leading: const Icon(Icons.directions_walk),
                            title: Text(DateFormat('d MMMM yyyy').format(stepCount.date)),
                            trailing: Text(
                              '${stepCount.steps} adım',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        },
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
} 