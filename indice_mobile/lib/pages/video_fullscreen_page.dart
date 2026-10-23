import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../widgets/video_view.dart';

/// Affiche en paysage, sur tout l'écran, une vidéo déjà chargée.
/// Le même contrôleur est réutilisé : la lecture continue sans recharger.
class VideoFullscreenPage extends StatefulWidget {
  const VideoFullscreenPage({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: VideoView(
            controller: widget.controller,
            isFullscreen: true,
            onFullscreenTap: () => context.pop(),
          ),
        ),
      ),
    );
  }
}
