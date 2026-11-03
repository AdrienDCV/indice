import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'http.dart';
import 'injection.dart';
import 'repositories/etf_repository.dart';
import 'repositories/resource_repository.dart';
import 'router.dart';
import 'stores/etf/etf_catalog_store.dart';
import 'stores/resource/resource_catalog_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // L'app reste en portrait ; seule la vidéo en plein écran passe en paysage.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: '.env.local');
  setupHttpClient();
  final cacheDirectory = await getApplicationCacheDirectory();
  configureDependencies(Directory('${cacheDirectory.path}/api_cache'));
  runApp(IndiceApp(router: buildRouter()));
}

class IndiceApp extends StatelessWidget {
  const IndiceApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => EtfCatalogStore(getIt<EtfRepository>())..init(),
        ),
        BlocProvider(
          create: (_) =>
              ResourceCatalogStore(getIt<ResourceRepository>())..init(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Indice',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }
}
