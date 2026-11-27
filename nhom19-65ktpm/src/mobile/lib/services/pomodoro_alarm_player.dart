import 'package:audioplayers/audioplayers.dart';

abstract interface class PomodoroAlarmPlayer {
  Future<void> play();
  Future<void> dispose();
}

class AssetPomodoroAlarmPlayer implements PomodoroAlarmPlayer {
  AudioPlayer? _player;

  @override
  Future<void> play() async {
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.play(AssetSource('audio/pomodoro_bell.wav'));
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
