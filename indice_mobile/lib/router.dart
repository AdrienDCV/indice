import 'package:go_router/go_router.dart';

import 'screens/compare/etf_catalog_screen.dart';
import 'screens/compare/etf_comparison_screen.dart';
import 'screens/compare/etf_detail_screen.dart';
import 'screens/compare/etf_picker_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/learn/learn_screen.dart';
import 'screens/learn/resource_detail_screen.dart';
import 'screens/main_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          MainScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/compare',
              builder: (_, _) => const EtfCatalogScreen(),
              routes: [
                GoRoute(
                  path: 'comparison',
                  builder: (_, state) => EtfComparisonScreen(
                    etfA: state.uri.queryParameters['etfA'],
                  ),
                  routes: [
                    GoRoute(
                      path: 'etf-picker',
                      builder: (_, state) => EtfPickerScreen(
                        slot: EtfSlot.values.byName(
                          state.uri.queryParameters['slot']!,
                        ),
                        excludedTicker: state.uri.queryParameters['exclude'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'etf/:ticker',
                  builder: (_, state) =>
                      EtfDetailScreen(ticker: state.pathParameters['ticker']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/resource/:id',
      builder: (_, state) =>
          ResourceDetailScreen(id: state.pathParameters['id']!),
    ),
  ],
);
