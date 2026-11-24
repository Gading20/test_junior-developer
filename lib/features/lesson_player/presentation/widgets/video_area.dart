import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../courses/domain/entities/course.dart';
import 'player_controls.dart';
import 'youtube_video_area.dart';

/// The video itself: surface, controls, loading and error overlays.
///
/// Owns the [VideoPlayerController] so the player lifecycle lives in
/// exactly one place:
///  * created in [initState] for the lesson passed in,
///  * paused when [isActive] flips to false (lesson switch starts),
///  * paused when the app leaves the foreground ([WidgetsBindingObserver]),
///  * paused and disposed in [dispose], which runs on route pop and on
///    lesson change — so two videos are never audible at once.
class VideoArea extends StatefulWidget {
  const VideoArea({
    super.key,
    required this.lesson,
    required this.isActive,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.onBack,
    this.onPrevious,
    this.onNext,
  });

  final Lesson lesson;

  /// False while this route is being replaced: the outgoing player has
  /// to stop before the next lesson starts.
  final bool isActive;

  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  /// Fullscreen only (portrait has an AppBar back button).
  final VoidCallback? onBack;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<VideoArea> createState() => _VideoAreaState();
}

class _VideoAreaState extends State<VideoArea> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  String? _initError;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(covariant VideoArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    if (controller != null) {
      // Stop first, release second: audio must not outlive this widget.
      _pause();
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  void _pause() {
    final controller = _controller;
    if (controller != null) unawaited(controller.pause());
  }

  /// Creates the controller for the current lesson. Called from
  /// [initState] (setState is not allowed there) and from [_retry]
  /// (wrapped in setState by the caller).
  void _start() {
    _initError = null;
    if (_youtubeId != null) return;
    final controller = _createController();
    _controller = controller;
    if (controller != null) unawaited(_initialize(controller));
  }

  String? get _youtubeId {
    final uri = Uri.tryParse(widget.lesson.videoUrl);
    if (uri == null || uri.scheme != 'https') return null;
    final id = switch (uri.host) {
      'www.youtube.com' || 'youtube.com' => uri.queryParameters['v'],
      'youtu.be' => uri.pathSegments.firstOrNull,
      _ => null,
    };
    return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  }

  /// null when the stored URL is not a playable http(s) address: there
  /// is nothing to initialize, so the error overlay is shown directly.
  VideoPlayerController? _createController() {
    final uri = Uri.tryParse(widget.lesson.videoUrl);
    final isHttp =
        uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    if (uri == null || uri.host.isEmpty || !isHttp) {
      _initError = 'Tautan video tidak valid.';
      return null;
    }
    return VideoPlayerController.networkUrl(uri);
  }

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      await controller.initialize();
    } catch (error) {
      // The lesson may have been replaced while the video was loading.
      if (!mounted || !identical(_controller, controller)) return;
      setState(() => _initError = _messageFor(error));
    }
  }

  void _retry() {
    final old = _controller;
    if (old != null) unawaited(old.dispose());
    setState(_start);
  }

  /// Turns a platform/technical error into a message a student can act
  /// on. Each cause gets its own wording, like the course screens.
  String _messageFor(Object error) {
    if (error is FormatException) return 'Tautan video tidak valid.';
    if (error is TimeoutException) {
      return 'Waktu memuat video habis. Periksa koneksi Anda lalu coba lagi.';
    }
    final text = error.toString();
    if (text.contains('404') || text.contains('403')) {
      return 'Video tidak dapat diakses. Coba lagi nanti.';
    }
    return 'Video tidak dapat diputar. Periksa koneksi Anda lalu coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final youtubeId = _youtubeId;
    if (youtubeId != null) {
      return YoutubeVideoArea(videoId: youtubeId, isActive: widget.isActive);
    }
    final controller = _controller;
    final initError = _initError;
    if (controller == null || initError != null) {
      return ColoredBox(
        color: AppColors.playerBackground,
        child: _VideoErrorOverlay(
          message:
              initError ??
              'Video tidak dapat diputar. Periksa koneksi Anda lalu coba lagi.',
          onRetry: _retry,
          onBack: widget.isFullscreen ? widget.onBack : null,
        ),
      );
    }

    return ColoredBox(
      color: AppColors.playerBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(controller),
          // Tapping the video (or any transparent part of the controls)
          // shows or hides the controls. No auto-hide timer: a paused
          // player must never lose its controls on its own.
          GestureDetector(
            key: const Key('video-tap-area'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _controlsVisible = !_controlsVisible),
            child: const SizedBox.expand(),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final value = controller.value;
              if (value.hasError) {
                return _VideoErrorOverlay(
                  message:
                      'Video terhenti. Periksa koneksi Anda lalu coba lagi.',
                  onRetry: _retry,
                  onBack: widget.isFullscreen ? widget.onBack : null,
                );
              }
              if (!value.isInitialized) {
                return const _VideoLoadingOverlay();
              }
              if (!_controlsVisible) return const SizedBox.shrink();
              return PlayerControls(
                controller: controller,
                title: widget.lesson.title,
                isFullscreen: widget.isFullscreen,
                onBack: widget.isFullscreen ? widget.onBack : null,
                onToggleFullscreen: widget.onToggleFullscreen,
                onPrevious: widget.onPrevious,
                onNext: widget.onNext,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VideoLoadingOverlay extends StatelessWidget {
  const _VideoLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.playerBackground,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.textInverse,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class _VideoErrorOverlay extends StatelessWidget {
  const _VideoErrorOverlay({
    required this.message,
    required this.onRetry,
    this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.playerBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (onBack != null)
            Positioned(
              top: 0,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: IconButton(
                  onPressed: onBack,
                  tooltip: 'Kembali',
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
          Center(
            // The stage is short (16:9 on a 360dp screen), so the error
            // content must be allowed to scroll instead of overflowing.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 36,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textInverse,
                      side: const BorderSide(color: AppColors.textInverse),
                    ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
