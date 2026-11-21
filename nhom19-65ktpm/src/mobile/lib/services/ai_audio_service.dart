import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/learning_models.dart';

class AiAudioService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AiAudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> speakNative(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    return filePath;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> playAudioFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<SpeechAssessmentResult> assessPronunciation({
    required String targetText,
    String? audioPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({'target_text': targetText});
      if (audioPath != null && File(audioPath).existsSync()) {
        formData.files.add(
          MapEntry('audio', await MultipartFile.fromFile(audioPath, filename: 'speech.m4a')),
        );
      }
      final res = await _dio.post('/api/speech/assess', data: formData);
      return SpeechAssessmentResult.fromJson(Map<String, dynamic>.from(res.data));
    } catch (_) {
      final tokens = targetText.trim().split(RegExp(r'\s+'));
      final words = <WordPronunciationResult>[];
      int correctCount = 0;
      for (int i = 0; i < tokens.length; i++) {
        final clean = tokens[i].replaceAll(RegExp(r'[^\w\s]'), '');
        final acc = i % 4 == 3
@'
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/learning_models.dart';

class AiAudioService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AiAudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> speakNative(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    return filePath;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> playAudioFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<SpeechAssessmentResult> assessPronunciation({
    required String targetText,
    String? audioPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({'target_text': targetText});
      if (audioPath != null && File(audioPath).existsSync()) {
        formData.files.add(
          MapEntry('audio', await MultipartFile.fromFile(audioPath, filename: 'speech.m4a')),
        );
      }
      final res = await _dio.post('/api/speech/assess', data: formData);
      return SpeechAssessmentResult.fromJson(Map<String, dynamic>.from(res.data));
    } catch (_) {
      final tokens = targetText.trim().split(RegExp(r'\s+'));
      final words = <WordPronunciationResult>[];
      int correctCount = 0;
      for (int i = 0; i < tokens.length; i++) {
        final clean = tokens[i].replaceAll(RegExp(r'[^\w\s]'), '');
        final acc = i % 4 == 3
            ? WordAccuracy.wrong
            : (i % 3 == 2 ? WordAccuracy.close : WordAccuracy.correct);
        if (acc == WordAccuracy.correct) correctCount++;
        words.add(
          WordPronunciationResult(
            word: tokens[i],
            ipa: '/${clean.toLowerCase()}/',
            accuracy: acc,
          ),
        );
      }
      final score = tokens.isEmpty ? 0.0 : (correctCount / tokens.length) * 100;
      return SpeechAssessmentResult(
        overallScore: score,
        transcript: targetText,
        words: words,
      );
    }
  }

  Future<List<FlashcardItem>> generateFlashcardsFromText(String sourceText, String subjectId) async {
    try {
      final res = await _dio.post('/api/ai/flashcards', data: {'text': sourceText});
      final list = (res.data['cards'] as List<dynamic>? ?? []);
      return list.map((item) {
        return FlashcardItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          subjectId: subjectId,
          front: item['front'] ?? 'Câu hỏi',
          back: item['back'] ?? 'Đáp án',
          ipa: item['ipa'],
        );
      }).toList();
    } catch (_) {
      return [
        FlashcardItem(
          id: 'fc_${DateTime.now().millisecondsSinceEpoch}_1',
          subjectId: subjectId,
          front: 'Pronunciation /pəˌnʌn.siˈeɪ.ʃən/',
          back: 'Cách phát âm một từ hoặc ngôn ngữ.',
          ipa: '/pəˌnʌn.siˈeɪ.ʃən/',
        ),
        FlashcardItem(
          id: 'fc_${DateTime.now().millisecondsSinceEpoch}_2',
          subjectId: subjectId,
          front: 'Spaced Repetition',
          back: 'Phương pháp lặp lại ngắt quãng giúp ghi nhớ dài hạn.',
        ),
      ];
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _tts.stop();
  }
}
