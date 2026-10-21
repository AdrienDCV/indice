import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../pages/video_fullscreen_page.dart';
import 'video_view.dart';

class ResourceVideoPlayer extends StatefulWidget {
  const ResourceVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<ResourceVideoPlayer> createState() => _ResourceVideoPlayerState();
}

class _ResourceVideoPlayerState extends State<ResourceVideoPlayer> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _hasLoadingError = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then(
      (_) {
        if (mounted) setState(() {});
      },
      onError: (Object error) {
        if (mounted) setState(() => _hasLoadingError = true);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (_hasLoadingError || value.hasError) {
              return const Center(
                child: Text(
                  'Impossible de lire la vidéo.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (!value.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return VideoView(
              controller: _controller,
              isFullscreen: false,
              onFullscreenTap: () =>
                  Navigator.of(context)
                      .push(VideoFullscreenPage.route(_controller)),
            );
          },
        ),
      ),
    );
  }
}
