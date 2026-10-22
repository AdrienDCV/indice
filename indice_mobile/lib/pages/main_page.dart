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

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  static const _learnIndex = 3;

  int _selectedIndex = 0;

  /// Fait apparaître l'onglet choisi en fondu, en remontant légèrement.
  late final AnimationController _transitionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _transitionController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _transitionController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomePage(onLearnTap: () => _selectTab(_learnIndex)),
              const BuildPage(),
              const ComparePage(),
              const LearnPage(resources: fakeResources),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
