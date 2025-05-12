class Meal {
  final String id;
  final String name;
  final int calories;
  final DateTime date;
  final String? imagePath;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.date,
    this.imagePath,
  });

  // JSON'dan model oluşturmak için factory constructor
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      date: DateTime.parse(json['date'] as String),
      imagePath: json['imagePath'] as String?,
    );
  }

  // Model'i JSON'a dönüştürmek için method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
    };
  }
} 