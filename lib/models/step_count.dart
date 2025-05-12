class StepCount {
  final int? id;
  final DateTime date;
  final int steps;

  StepCount({
    this.id,
    required this.date,
    required this.steps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'steps': steps,
    };
  }

  factory StepCount.fromMap(Map<String, dynamic> map) {
    return StepCount(
      id: map['id'],
      date: DateTime.parse(map['date']),
      steps: map['steps'],
    );
  }
} 