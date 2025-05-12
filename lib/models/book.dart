import 'package:flutter/foundation.dart';

class Book {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String summary;
  final String imagePath;

  Book({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'summary': summary,
      'imagePath': imagePath,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      summary: map['summary'],
      imagePath: map['imagePath'],
    );
  }
} 