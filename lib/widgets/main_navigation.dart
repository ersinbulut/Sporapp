import 'package:flutter/material.dart';

class MainNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const MainNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_walk),
          label: 'Adım Sayacı',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Egzersizler',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Yemekler',
        ),
      ],
    );
  }
} 