import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Uses the official iframe player rather than extracting YouTube streams.
class YoutubeVideoArea extends StatefulWidget {
  const YoutubeVideoArea({
    super.key,
    required this.videoId,
    required this.isActive,
  });

  final String videoId;
  final bool isActive;

  @override
  State<YoutubeVideoArea> createState() => _YoutubeVideoAreaState();
}

class _YoutubeVideoAreaState extends State<YoutubeVideoArea>
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createController();
  }

  void _createController() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: false),
    );
  }

  @override
  void didUpdateWidget(covariant YoutubeVideoArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      unawaited(_controller.close());
      _createController();
    } else if (!widget.isActive) {
      unawaited(_controller.pauseVideo());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller.pauseVideo());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayer(
    key: ValueKey(widget.videoId),
    controller: _controller,
    keepAlive: true,
    autoFullScreen: false,
    enableFullScreenOnVerticalDrag: false,
  );
}
