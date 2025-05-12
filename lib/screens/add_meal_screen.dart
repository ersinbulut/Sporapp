import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/database_helper.dart';
import '../models/meal.dart';

class AddMealScreen extends StatefulWidget {
  final Meal? meal;
  final String? initialMealType;

  const AddMealScreen({Key? key, this.meal, this.initialMealType}) : super(key: key);

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  String? _imagePath;
  String _selectedMealType = 'Kahvaltı';

  final List<String> _mealTypes = [
    'Kahvaltı',
    'Öğle Yemeği',
    'Ara Öğün',
    'Akşam Yemeği',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.meal != null) {
      _nameController.text = widget.meal!.name;
      _caloriesController.text = widget.meal!.calories.toString();
      _imagePath = widget.meal!.imagePath;
      _selectedMealType = widget.meal!.mealType;
    } else if (widget.initialMealType != null) {
      _selectedMealType = widget.initialMealType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        print('Seçilen resim yolu: $_imagePath');
      }
    } catch (e) {
      print('Resim seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.meal != null) {
          // Güncelleme
          final updatedMeal = Meal(
            id: widget.meal!.id,
            name: _nameController.text,
            calories: int.parse(_caloriesController.text),
            date: widget.meal!.date,
            imagePath: _imagePath,
            mealType: _selectedMealType,
          );
          print('Güncellenecek yemek resmi: ${updatedMeal.imagePath}');
          await _dbHelper.updateMeal(updatedMeal);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yemek başarıyla güncellendi')),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Ekleme
          final meal = Meal(
            id: DateTime.now().toString(),
            name: _nameController.text,
            calories: int.parse(_caloriesController.text),
            date: '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            imagePath: _imagePath,
            mealType: _selectedMealType,
          );
          print('Eklenecek yemek resmi: ${meal.imagePath}');
          await _dbHelper.insertMeal(meal);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yemek başarıyla kaydedildi')),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        print('Yemek kaydetme hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata oluştu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal != null ? 'Yemeği Güncelle' : 'Yeni Yemek Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: _imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imagePath == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Resim Ekle', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Öğün',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: _mealTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir öğün seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Yemek Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yemek adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Kalori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kalori miktarını girin';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Lütfen geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.meal != null ? 'Güncelle' : 'Kaydet',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 