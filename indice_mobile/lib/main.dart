import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/main_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // L'app reste en portrait ; seule la vidéo en plein écran passe en paysage.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const IndiceApp());
}

class IndiceApp extends StatelessWidget {
  const IndiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indice',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainPage(),
    );
  }
}
