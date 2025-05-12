class Meal {
  final String id;
  final String name;
  final int calories;
  final String date;
  final String? imagePath;
  final String mealType;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.date,
    this.imagePath,
    required this.mealType,
  });

  // JSON'dan model oluşturmak için factory constructor
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      date: json['date'] as String,
      imagePath: json['imagePath'] as String?,
      mealType: json['mealType'] as String,
    );
  }

  // Model'i JSON'a dönüştürmek için method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'date': date,
      'imagePath': imagePath,
      'mealType': mealType,
    };
  }
} 