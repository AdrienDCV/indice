import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'data/fake_resources.dart';
import 'models/resource.dart';
import 'pages/build_page.dart';
import 'pages/compare_page.dart';
import 'pages/home_page.dart';
import 'pages/learn_page.dart';
import 'pages/main_page.dart';
import 'pages/resource_detail_page.dart';
import 'pages/video_fullscreen_page.dart';

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
            GoRoute(path: '/build', builder: (_, _) => const BuildPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/compare', builder: (_, _) => const ComparePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (_, _) => const LearnPage(resources: fakeResources),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/resource',
      builder: (_, state) =>
          ResourceDetailPage(resource: state.extra! as Resource),
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
