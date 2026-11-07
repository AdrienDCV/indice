import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const playerHost = 'com.fisa.indicemobile';
const playerOrigin = 'https://$playerHost';

String youtubePlayerHtml(String videoId) =>
    '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>html, body { margin: 0; height: 100%; background: #000; } iframe { border: 0; width: 100%; height: 100%; }</style>
</head>
<body>
<iframe
  src="https://www.youtube-nocookie.com/embed/$videoId?playsinline=1&fs=0&rel=0"
  allow="autoplay; encrypted-media; picture-in-picture"
  referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body>
</html>
''';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late final String? _videoId = Uri.tryParse(widget.url)?.queryParameters['v'];
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = _videoId;
    if (videoId == null) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _stayOnPlayer),
      )
      ..loadHtmlString(youtubePlayerHtml(videoId), baseUrl: playerOrigin);
  }

  NavigationDecision _stayOnPlayer(NavigationRequest request) {
    final leavesPlayer =
        request.isMainFrame && Uri.tryParse(request.url)?.host != playerHost;
    return leavesPlayer
        ? NavigationDecision.prevent
        : NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: controller == null
            ? const Center(
                child: Text(
                  'Impossible de lire la vidéo.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : WebViewWidget(controller: controller),
      ),
    );
  }
}
