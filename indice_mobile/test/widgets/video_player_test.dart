import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:indice_mobile/widgets/video_player.dart';

import '../fakes/fake_webview_platform.dart';

Future<FakeWebViewPlatform> pumpPlayer(WidgetTester tester, String url) async {
  final platform = FakeWebViewPlatform();
  WebViewPlatform.instance = platform;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: VideoPlayer(url: url)),
    ),
  );
  return platform;
}

void main() {
  testWidgets('plays the youtube video inside the app', (
    WidgetTester tester,
  ) async {
    final platform = await pumpPlayer(
      tester,
      'https://www.youtube.com/watch?v=lA6b8tckrQQ',
    );

    final controller = platform.controllers.single;
    expect(
      controller.html,
      contains('https://www.youtube-nocookie.com/embed/lA6b8tckrQQ'),
    );
    expect(controller.baseUrl, playerOrigin);
    expect(find.text('Impossible de lire la vidéo.'), findsNothing);
  });

  testWidgets('keeps the player when youtube tries to leave it', (
    WidgetTester tester,
  ) async {
    final platform = await pumpPlayer(
      tester,
      'https://www.youtube.com/watch?v=lA6b8tckrQQ',
    );
    final onNavigationRequest =
        platform.controllers.single.navigationDelegate!.onNavigationRequest!;

    expect(
      await onNavigationRequest(
        const NavigationRequest(
          url: 'https://www.youtube.com/watch?v=lA6b8tckrQQ',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      await onNavigationRequest(
        const NavigationRequest(
          url: 'https://www.youtube-nocookie.com/embed/lA6b8tckrQQ',
          isMainFrame: false,
        ),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await onNavigationRequest(
        const NavigationRequest(url: playerOrigin, isMainFrame: true),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await onNavigationRequest(
        const NavigationRequest(
          url: 'https://com.fisa.indicemobile.attacker.com',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
  });

  testWidgets('shows a message when the url is not a youtube video', (
    WidgetTester tester,
  ) async {
    final platform = await pumpPlayer(
      tester,
      'https://example.com/media/lesson.mp4',
    );

    expect(platform.controllers, isEmpty);
    expect(find.text('Impossible de lire la vidéo.'), findsOneWidget);
  });
}
