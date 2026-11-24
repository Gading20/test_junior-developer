import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// In-memory [VideoPlayerPlatform] for widget tests.
///
/// No codec, no network: [createWithOptions] queues an "initialized"
/// event on a non-broadcast stream, so the event is buffered until
/// VideoPlayerController subscribes and `initialize()` completes
/// without touching a real platform.
///
/// Every playback command is recorded, which is how the tests assert
/// "this video was paused" or "only one player was ever created".
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int nextId = 0;
  final Map<int, StreamController<VideoEvent>> _events = {};
  final Map<int, VideoCreationOptions> created = {};
  final List<int> disposed = [];
  final List<int> played = [];
  final List<int> paused = [];
  final List<(int, Duration)> seeks = [];

  Duration duration = const Duration(seconds: 90);
  Duration position = Duration.zero;
  Size videoSize = const Size(640, 360);

  /// When set, the next creation fails with a platform error, which is
  /// how a broken/undeliverable stream reaches the error state.
  String? failWith;

  /// Simulates a stream that breaks after playback has started.
  void emitConnectionLost(int playerId) {
    _events[playerId]!.addError(
      PlatformException(code: 'VideoError', message: 'Connection lost'),
    );
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = nextId++;
    created[id] = options;
    final events = StreamController<VideoEvent>();
    _events[id] = events;
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      events.addError(PlatformException(code: 'VideoError', message: failure));
    } else {
      events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: duration,
          size: videoSize,
        ),
      );
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    played.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {
    paused.add(playerId);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration newPosition) async {
    seeks.add((playerId, newPosition));
    position = newPosition;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool value,
  ) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => _surface;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => _surface;

  static const Widget _surface = ColoredBox(
    key: Key('fake-video-surface'),
    color: Color(0xFF000000),
    child: SizedBox.expand(),
  );

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    final events = _events.remove(playerId);
    await events?.close();
  }
}
