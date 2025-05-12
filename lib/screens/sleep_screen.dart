import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/sleep_record.dart';
import 'package:intl/intl.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({Key? key}) : super(key: key);

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  List<SleepRecord> _records = [];
  double _todaySleep = 0;

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    final db = DatabaseHelper();
    final allRecords = await db.getAllSleepRecords();
    final today = DateTime.now();
    final todayRecords = allRecords.where((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day).toList();
    setState(() {
      _records = allRecords;
      _todaySleep = todayRecords.fold(0.0, (sum, r) => sum + r.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uyku Takibi'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSleepData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bugünkü Toplam Uyku', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_todaySleep.toStringAsFixed(1)} saat', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Geçmiş Uyku Kayıtları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Kayıt yok'),
                ),
              )
            else
              ..._records.map((r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.bedtime, color: Colors.blue),
                      title: Text('${r.duration.toStringAsFixed(1)} saat'),
                      subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(r.date)),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
} 