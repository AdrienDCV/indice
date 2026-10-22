import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Vidéo déjà chargée, avec ses contrôles (lecture, progression, plein écran).
class VideoView extends StatelessWidget {
  const VideoView({
    super.key,
    required this.controller,
    required this.isFullscreen,
    required this.onFullscreenTap,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback onFullscreenTap;

  void _togglePlayPause(VideoPlayerValue value) {
    if (value.isPlaying) {
      controller.pause();
      return;
    }
    if (value.position >= value.duration) {
      controller.seekTo(Duration.zero);
    }
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _togglePlayPause(value),
              ),
            ),
            if (!value.isPlaying)
              const IgnorePointer(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(left: 12),
                      colors: VideoProgressColors(
                        playedColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onFullscreenTap,
                    tooltip: isFullscreen
                        ? 'Quitter le plein écran'
                        : 'Plein écran',
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
