class Workout {
  final String id;
  final String name;
  final int duration; // dakika cinsinden
  final int caloriesBurned;
  final DateTime date;

  Workout({
    required this.id,
    required this.name,
    required this.duration,
    required this.caloriesBurned,
    required this.date,
  });

  // JSON'dan model oluşturmak için factory constructor
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: json['duration'] as int,
      caloriesBurned: json['caloriesBurned'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Model'i JSON'a dönüştürmek için method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
    };
  }
} 