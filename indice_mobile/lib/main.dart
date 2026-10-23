import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // L'app reste en portrait ; seule la vidéo en plein écran passe en paysage.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(IndiceApp(router: buildRouter()));
}

class IndiceApp extends StatelessWidget {
  const IndiceApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Indice',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
