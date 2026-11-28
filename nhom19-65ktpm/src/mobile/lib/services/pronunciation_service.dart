import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String pronunciationReferenceText =
    'Practice makes perfect every single day.';
const String pronunciationReferenceIpa =
    '/ˈpræktɪs meɪks ˈpɝːfɪkt ˈɛvri ˈsɪŋɡəl deɪ/';

enum PronunciationWordStatus {
  correct,
  warning,
  error,
}

class PronunciationWordResult {
  const PronunciationWordResult({
    required this.word,
    required this.ipa,
    required this.score,
    required this.status,
  });

  final String word;
  final String ipa;
  final double score;
  final PronunciationWordStatus status;

  factory PronunciationWordResult.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'correct' => PronunciationWordStatus.correct,
      'warning' || 'close' => PronunciationWordStatus.warning,
      'error' || 'wrong' => PronunciationWordStatus.error,
      final value => throw FormatException(
          'Trạng thái phát âm không được hỗ trợ: $value',
        ),
    };

    return PronunciationWordResult(
      word: json['word'] as String,
      ipa: json['ipa'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      status: status,
    );
  }
}

class PronunciationResult {
  const PronunciationResult({
    required this.score,
    required this.targetText,
    required this.transcript,
    required this.words,
  });

  final double score;
  final String targetText;
  final String transcript;
  final List<PronunciationWordResult> words;

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>;
    return PronunciationResult(
      score: ((json['overall_score'] ?? json['score']) as num).toDouble(),
      targetText: json['target_text'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      words: rawWords
          .map(
            (word) => PronunciationWordResult.fromJson(
              Map<String, dynamic>.from(word as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class PronunciationApiException implements Exception {
  const PronunciationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PronunciationService {
  PronunciationService({http.Client? client, Uri? apiBaseUri})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _apiBaseUri = apiBaseUri ?? _defaultApiBaseUri;

  final http.Client _client;
  final bool _ownsClient;
  final Uri _apiBaseUri;

  static Uri get _defaultApiBaseUri {
    const configuredUrl = String.fromEnvironment('STUDYMATE_API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return Uri.parse(
          configuredUrl.endsWith('/') ? configuredUrl : '$configuredUrl/');
    }

    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return Uri(scheme: 'http', host: host, port: 8000);
  }

  Future<PronunciationResult> evaluate({
    required Uint8List wavAudio,
    required String targetText,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _apiBaseUri.resolve('/api/speech/evaluate'),
    )
      ..fields['target_text'] = targetText
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          wavAudio,
          filename: 'pronunciation.wav',
        ),
      );

    final streamedResponse =
        await _client.send(request).timeout(const Duration(minutes: 2));
    final body = await streamedResponse.stream
        .bytesToString()
        .timeout(const Duration(minutes: 2));

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw PronunciationApiException(
        'Backend trả về dữ liệu không hợp lệ (HTTP ${streamedResponse.statusCode}).',
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      throw PronunciationApiException(
        detail?.toString() ??
            'Không thể chấm điểm phát âm (HTTP ${streamedResponse.statusCode}).',
      );
    }
    if (decoded is! Map) {
      throw const PronunciationApiException(
        'Backend trả về kết quả chấm điểm không đúng định dạng.',
      );
    }

    return PronunciationResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

Uint8List pcm16ToWav(
  Uint8List pcmBytes, {
  int sampleRate = 16000,
  int channels = 1,
}) {
  if (pcmBytes.isEmpty || pcmBytes.length.isOdd) {
    throw ArgumentError.value(pcmBytes.length, 'pcmBytes.length');
  }

  const bytesPerSample = 2;
  final byteRate = sampleRate * channels * bytesPerSample;
  final blockAlign = channels * bytesPerSample;
  final wavBytes = Uint8List(44 + pcmBytes.length);
  final data = ByteData.sublistView(wavBytes);

  void writeTag(int offset, String tag) {
    for (var index = 0; index < tag.length; index++) {
      wavBytes[offset + index] = tag.codeUnitAt(index);
    }
  }

  writeTag(0, 'RIFF');
  data.setUint32(4, 36 + pcmBytes.length, Endian.little);
  writeTag(8, 'WAVE');
  writeTag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, byteRate, Endian.little);
  data.setUint16(32, blockAlign, Endian.little);
  data.setUint16(34, 16, Endian.little);
  writeTag(36, 'data');
  data.setUint32(40, pcmBytes.length, Endian.little);
  wavBytes.setRange(44, wavBytes.length, pcmBytes);
  return wavBytes;
}
