import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout.dart';
import '../models/meal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/book.dart';
import '../models/step_count.dart';
import '../models/sleep_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Sadece masaüstü platformlarda FFI başlat
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    String path = join(await getDatabasesPath(), 'sporapp.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Workout tablosu
    await db.execute('''
      CREATE TABLE workouts(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        caloriesBurned INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Meal tablosu
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT,
        mealType TEXT NOT NULL
      )
    ''');

    // Step Count tablosu
    await db.execute('''
      CREATE TABLE step_counts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL
      )
    ''');

    // Kullanıcı hedefleri tablosu
    await db.execute('''
      CREATE TABLE user_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_calorie_goal INTEGER NOT NULL,
        daily_workout_minutes INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Book tablosu
    await db.execute('''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        summary TEXT NOT NULL,
        imagePath TEXT NOT NULL
      )
    ''');

    // Sleep Records tablosu
    await db.execute('''
      CREATE TABLE sleep_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration REAL NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Book tablosunu oluştur
      await db.execute('''
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          summary TEXT NOT NULL,
          imagePath TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Meal tablosuna imagePath sütununu ekle
      await db.execute('ALTER TABLE meals ADD COLUMN imagePath TEXT');
    }

    if (oldVersion < 4) {
      // Step Count tablosunu oluştur
      await db.execute('''
        CREATE TABLE step_counts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          steps INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      // Meal tablosuna mealType sütununu ekle
      await db.execute('ALTER TABLE meals ADD COLUMN mealType TEXT NOT NULL DEFAULT "Kahvaltı"');
    }
  }

  // Kullanıcı hedeflerini kaydetme
  Future<int> saveUserGoals({
    required int dailyCalorieGoal,
    required int dailyWorkoutMinutes,
  }) async {
    final db = await database;
    
    // Önceki hedefleri sil
    await db.delete('user_goals');
    
    // Yeni hedefleri kaydet
    return await db.insert('user_goals', {
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_workout_minutes': dailyWorkoutMinutes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Kullanıcı hedeflerini getirme
  Future<Map<String, int>?> getUserGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_goals',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return {
      'daily_calorie_goal': maps[0]['daily_calorie_goal'] as int,
      'daily_workout_minutes': maps[0]['daily_workout_minutes'] as int,
    };
  }

  // Workout CRUD işlemleri
  Future<int> insertWorkout(Workout workout) async {
    Database db = await database;
    return await db.insert('workouts', workout.toJson());
  }

  Future<List<Workout>> getWorkouts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('workouts');
    return List.generate(maps.length, (i) => Workout.fromJson(maps[i]));
  }

  Future<int> updateWorkout(Workout workout) async {
    Database db = await database;
    return await db.update(
      'workouts',
      workout.toJson(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> deleteWorkout(String id) async {
    Database db = await database;
    return await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Meal CRUD işlemleri
  Future<int> insertMeal(Meal meal) async {
    Database db = await database;
    return await db.insert('meals', meal.toJson());
  }

  Future<List<Meal>> getMeals() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('meals');
    return List.generate(maps.length, (i) => Meal.fromJson(maps[i]));
  }

  Future<int> updateMeal(Meal meal) async {
    Database db = await database;
    return await db.update(
      'meals',
      meal.toJson(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(String id) async {
    Database db = await database;
    return await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tarihe göre filtreleme metodları
  Future<List<Workout>> getWorkoutsByDate(DateTime date) async {
    Database db = await database;
    final String dateString = date.toIso8601String().substring(0, 10); // 'yyyy-MM-dd'
    final List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      where: "date(date) = ?",
      whereArgs: [dateString],
    );
    return List.generate(maps.length, (i) => Workout.fromJson(maps[i]));
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    Database db = await database;
    final String dateString = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: "date = ?",
      whereArgs: [dateString],
    );
    return List.generate(maps.length, (i) => Meal.fromJson(maps[i]));
  }

  // Günlük kalori hesaplama metodu
  Future<Map<String, int>> getDailyCalorieSummary(DateTime date) async {
    final workouts = await getWorkoutsByDate(date);
    final meals = await getMealsByDate(date);

    // Toplam yakılan kalori
    final totalCaloriesBurned = workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.caloriesBurned,
    );

    // Toplam alınan kalori
    final totalCaloriesConsumed = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    // Net kalori (alınan - yakılan)
    final netCalories = totalCaloriesConsumed - totalCaloriesBurned;

    return {
      'consumed': totalCaloriesConsumed,
      'burned': totalCaloriesBurned,
      'net': netCalories,
    };
  }

  // Book CRUD işlemleri
  Future<int> insertBook(Book book) async {
    Database db = await database;
    return await db.insert('books', book.toMap());
  }

  Future<List<Book>> getBooks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'startDate DESC');
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<int> updateBook(Book book) async {
    Database db = await database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    Database db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Book?> getBookById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Book.fromMap(maps.first);
    }
    return null;
  }

  // Step Count CRUD işlemleri
  Future<void> saveStepCount(StepCount stepCount) async {
    final db = await database;
    await db.insert(
      'step_counts',
      stepCount.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StepCount?> getStepCountByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'step_counts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    if (maps.isEmpty) {
      return null;
    }

    return StepCount.fromMap(maps.first);
  }

  Future<List<StepCount>> getStepCountsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'step_counts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return StepCount.fromMap(maps[i]);
    });
  }

  Future<void> deleteStepCount(int id) async {
    final db = await database;
    await db.delete(
      'step_counts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SleepRecord CRUD işlemleri
  Future<int> insertSleepRecord(SleepRecord record) async {
    Database db = await database;
    return await db.insert('sleep_records', record.toJson());
  }

  Future<List<SleepRecord>> getSleepRecordsByDate(DateTime date) async {
    Database db = await database;
    final String dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_records',
      where: "date(date) = ?",
      whereArgs: [dateString],
    );
    return List.generate(maps.length, (i) => SleepRecord.fromJson(maps[i]));
  }

  Future<List<SleepRecord>> getAllSleepRecords() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sleep_records', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => SleepRecord.fromJson(maps[i]));
  }
} 