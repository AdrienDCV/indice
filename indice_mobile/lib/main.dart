import 'package:flutter/material.dart';

import 'widgets/module_button.dart';

void main() {
  runApp(const IndiceApp());
}

class IndiceApp extends StatelessWidget {
  const IndiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Indice', home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accueil',
          style: TextStyle(
            color: Color(0xFF307A60),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prêt à découvrir\nl’investissement ?',
              style: TextStyle(color: Color(0xFF61B396), fontSize: 32),
            ),
            const SizedBox(height: 16),
            ModuleButton(
              title: 'Apprendre',
              subtitle: 'Comprendre les bases des ETF et de la finance',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
