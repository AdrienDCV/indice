import 'package:flutter/material.dart';

import 'pages/main_page.dart';

void main() {
  runApp(const IndiceApp());
}

class IndiceApp extends StatelessWidget {
  const IndiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF336C4C)),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF307A60),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}
