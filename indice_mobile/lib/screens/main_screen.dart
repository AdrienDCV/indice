import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      _transitionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.navigationShell),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
