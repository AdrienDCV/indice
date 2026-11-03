import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'pages/home_page.dart';
import 'pages/main_page.dart';
import 'pages/video_fullscreen_page.dart';
import 'screens/compare/etf_catalog_screen.dart';
import 'screens/compare/etf_comparison_screen.dart';
import 'screens/compare/etf_detail_screen.dart';
import 'screens/compare/etf_picker_screen.dart';
import 'screens/learn/learn_screen.dart';
import 'screens/learn/resource_detail_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          MainPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
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
    GoRoute(
      path: '/video',
      pageBuilder: (_, state) => MaterialPage(
        fullscreenDialog: true,
        child: VideoFullscreenPage(
          controller: state.extra! as VideoPlayerController,
        ),
      ),
    ),
  ],
);
