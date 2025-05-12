class Meal {
  final String id;
  final String name;
  final int calories;
<<<<<<< HEAD
  final String date;
  final String? imagePath;
  final String mealType;
=======
  final DateTime date;
  final String? imagePath;
>>>>>>> 8494d862e30e5fbae86f045862ea240d774c8d91

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.date,
    this.imagePath,
<<<<<<< HEAD
    required this.mealType,
=======
>>>>>>> 8494d862e30e5fbae86f045862ea240d774c8d91
  });

  // JSON'dan model oluşturmak için factory constructor
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
<<<<<<< HEAD
      date: json['date'] as String,
      imagePath: json['imagePath'] as String?,
      mealType: json['mealType'] as String,
=======
      date: DateTime.parse(json['date'] as String),
      imagePath: json['imagePath'] as String?,
>>>>>>> 8494d862e30e5fbae86f045862ea240d774c8d91
    );
  }

  // Model'i JSON'a dönüştürmek için method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
<<<<<<< HEAD
      'date': date,
      'imagePath': imagePath,
      'mealType': mealType,
=======
      'date': date.toIso8601String(),
      'imagePath': imagePath,
>>>>>>> 8494d862e30e5fbae86f045862ea240d774c8d91
    };
  }
} 