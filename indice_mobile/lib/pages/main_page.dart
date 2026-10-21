import 'package:flutter/material.dart';

import '../data/fake_resources.dart';
import '../widgets/app_navigation_bar.dart';
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
        children: const [
          HomePage(),
          BuildPage(),
          ComparePage(),
          LearnPage(resources: fakeResources),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}
