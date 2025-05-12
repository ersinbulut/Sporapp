import 'package:flutter/material.dart';
import '../models/book.dart';
import 'dart:io';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (book.imagePath.isNotEmpty && File(book.imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(book.imagePath),
                  width: 160,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 160,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.book, size: 64, color: Colors.grey),
              ),
            const SizedBox(height: 24),
            Text(
              book.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('Başlangıç: ${book.startDate.toLocal().toString().split(' ')[0]}'),
                const SizedBox(width: 16),
                const Icon(Icons.flag, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('Bitiş: ${book.endDate.toLocal().toString().split(' ')[0]}'),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Özet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(book.summary, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 