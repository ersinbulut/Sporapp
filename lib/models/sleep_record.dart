class SleepRecord {
  final int? id;
  final DateTime date;
  final double duration; // saat cinsinden

  SleepRecord({this.id, required this.date, required this.duration});

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      duration: json['duration'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
    };
  }
} 