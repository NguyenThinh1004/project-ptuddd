import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/learning_models.dart';
import '../services/ai_audio_service.dart';

class SpeechProvider extends ChangeNotifier {
  final AiAudioService _service;
  SpeechProvider(this._service);

  String targetSentence = 'Practice makes perfect every single day.';
  bool isRecording = false;
  String? lastAudioPath;
  bool isAssessing = false;
  SpeechAssessmentResult? result;
  List<double> waveformBars = List.generate(24, (_) => 0.2);

  Timer? _waveTimer;
  final Random _rng = Random();

  void setTargetSentence(String text) {
    targetSentence = text;
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    if (!isRecording) {
      final path = await _service.startRecording();
      lastAudioPath = path;
      isRecording = true;
      _startWave();
      notifyListeners();
    } else {
      isRecording = false;
      _stopWave();
      final path = await _service.stopRecording();
      if (path != null) lastAudioPath = path;
      notifyListeners();
      await assessCurrentSentence();
    }
  }

  void _startWave() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 110), (_) {
      waveformBars = List.generate(24, (_) => 0.15 + _rng.nextDouble() * 0.85);
      notifyListeners();
    });
  }

  void _stopWave() {
    _waveTimer?.cancel();
    waveformBars = List.generate(24, (_) => 0.2);
  }

  Future<void> speakTarget() async {
    await _service.speakNative(targetSentence);
  }

  Future<void> playUserRecording() async {
    if (lastAudioPath != null) {
      await _service.playAudioFile(lastAudioPath!);
    }
  }

  Future<void> assessCurrentSentence() async {
    isAssessing = true;
    notifyListeners();
    result = await _service.assessPronunciation(
      targetText: targetSentence,
      audioPath: lastAudioPath,
    );
    isAssessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }
}
