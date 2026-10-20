import 'package:flutter/material.dart';

import 'build_page.dart';
import 'compare_page.dart';
import 'home_page.dart';
import 'learn_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [HomePage(), BuildPage(), ComparePage(), LearnPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Construire',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Comparer',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Apprendre',
          ),
        ],
      ),
    );
  }
}
