import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';

/// Custom controls layered over the video surface.
///
/// Hand-written instead of chewie so every visual decision comes from
/// the design tokens, and so the four states (ready / buffering /
/// error / hidden) stay in one place.
///
/// Layout: top bar (back, lesson title, fullscreen), center
/// (play-pause or buffering spinner), bottom bar (times + scrubber).
/// The gaps between the three bars are transparent and fall through to
/// the tap area below, so tapping the video toggles the controls.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.controller,
    required this.title,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.onBack,
    this.onPrevious,
    this.onNext,
  });

  final VideoPlayerController controller;
  final String title;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  /// Fullscreen only: in portrait the AppBar already provides back.
  final VoidCallback? onBack;

  /// Fullscreen only: portrait exposes prev/next as labelled buttons
  /// below the video, where they are easier to hit than icons.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(
            title: title,
            isFullscreen: isFullscreen,
            onBack: onBack,
            onToggleFullscreen: onToggleFullscreen,
          ),
        ),
        Positioned.fill(
          child: Center(child: _CenterControl(controller: controller)),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomBar(
            controller: controller,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.onBack,
  });

  final String title;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.playerScrim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                tooltip: 'Kembali',
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.textInverse,
                ),
              )
            else
              // Keeps the title aligned with the AppBar title below it.
              const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
            IconButton(
              onPressed: onToggleFullscreen,
              tooltip: isFullscreen ? 'Keluar dari layar penuh' : 'Layar penuh',
              icon: Icon(
                isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterControl extends StatelessWidget {
  const _CenterControl({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        if (value.isBuffering) {
          return const SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.textInverse,
                strokeWidth: 3,
              ),
            ),
          );
        }
        return Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.playerScrim,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () =>
                value.isPlaying ? controller.pause() : controller.play(),
            tooltip: value.isPlaying ? 'Jeda' : 'Putar',
            iconSize: 32,
            icon: Icon(
              value.isPlaying ? LucideIcons.pause : LucideIcons.play,
              color: AppColors.textInverse,
            ),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, this.onPrevious, this.onNext});

  final VideoPlayerController controller;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.playerScrim,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (onPrevious != null)
              IconButton(
                onPressed: onPrevious,
                tooltip: 'Pelajaran sebelumnya',
                icon: const Icon(
                  LucideIcons.skipBack,
                  color: AppColors.textInverse,
                ),
              ),
            _TimeLabel(controller: controller, read: (value) => value.position),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.accent,
                  bufferedColor: AppColors.playerBuffered,
                  backgroundColor: AppColors.playerTrack,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TimeLabel(controller: controller, read: (value) => value.duration),
            if (onNext != null)
              IconButton(
                onPressed: onNext,
                tooltip: 'Pelajaran berikutnya',
                icon: const Icon(
                  LucideIcons.skipForward,
                  color: AppColors.textInverse,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One clock readout (position or duration). Separate widget so only
/// the two labels rebuild on every playback tick.
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.controller, required this.read});

  final VideoPlayerController controller;
  final Duration Function(VideoPlayerValue value) read;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Text(
          DurationFormatter.clock(read(controller.value).inSeconds),
          style: AppTypography.caption.copyWith(color: AppColors.textInverse),
        );
      },
    );
  }
}
