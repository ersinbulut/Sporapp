import 'dart:async';
import 'package:pedometer/pedometer.dart' hide StepCount;
import '../models/step_count.dart';
import '../helpers/database_helper.dart';

class StepCountService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Stream<StepCount> stepCountStream;
  DateTime _lastUpdate = DateTime.now();
  int _lastStepCount = 0;

  StepCountService() {
    _initializePedometer();
  }

  Future<void> _initializePedometer() async {
    try {
      stepCountStream = Pedometer.stepCountStream.map((event) {
        final now = DateTime.now();
        if (now.difference(_lastUpdate).inHours >= 24) {
          _lastStepCount = 0;
          _lastUpdate = now;
        }
        _lastStepCount = event.steps;
        return StepCount(
          id: null,
          date: now,
          steps: _lastStepCount,
        );
      });

      // Günlük adım sayısını veritabanına kaydet
      stepCountStream.listen((stepCount) async {
        await _dbHelper.saveStepCount(stepCount);
      });
    } catch (e) {
      print('Pedometer başlatılamadı: $e');
      // Hata durumunda boş bir stream oluştur
      stepCountStream = Stream.value(StepCount(
        id: null,
        date: DateTime.now(),
        steps: 0,
      ));
    }
  }

  Future<int> getTodayStepCount() async {
    final today = DateTime.now();
    final stepCount = await _dbHelper.getStepCountByDate(today);
    return stepCount?.steps ?? 0;
  }

  Future<int> getStepCountByDate(DateTime date) async {
    final stepCount = await _dbHelper.getStepCountByDate(date);
    return stepCount?.steps ?? 0;
  }

  Future<List<StepCount>> getStepCountHistory(DateTime startDate, DateTime endDate) async {
    return await _dbHelper.getStepCountsByDateRange(startDate, endDate);
  }
} 