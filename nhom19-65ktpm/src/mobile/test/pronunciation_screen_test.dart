import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/pronunciation_service.dart';
import 'package:mobile/views/pronunciation/pronunciation_screen.dart';

void main() {
  test('parses score and per-word statuses from the speech API response', () {
    final result = PronunciationResult.fromJson({
      'overall_score': 82.5,
      'score': 82.5,
      'target_text': pronunciationReferenceText,
      'transcript': 'practice makes perfect every single day',
      'words': [
        {
          'word': 'Practice',
          'ipa': '/ˈpræktɪs/',
          'score': 100,
          'status': 'correct'
        },
        {'word': 'makes', 'ipa': '/meɪks/', 'score': 65, 'status': 'warning'},
        {
          'word': 'perfect',
          'ipa': '/ˈpɝːfɪkt/',
          'score': 20,
          'status': 'error'
        },
      ],
    });

    expect(result.score, 82.5);
    expect(result.words[0].status, PronunciationWordStatus.correct);
    expect(result.words[1].status, PronunciationWordStatus.warning);
    expect(result.words[2].status, PronunciationWordStatus.error);
  });

  test('wraps PCM samples in a valid 16 kHz mono WAV container', () {
    final wav = pcm16ToWav(Uint8List.fromList([0, 0, 255, 127]));
    final data = ByteData.sublistView(wav);

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 16000);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), 4);
  });

  test('sends multipart recording to the speech endpoint and parses its JSON',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/speech/evaluate');
      expect(request, isA<http.Request>());
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data;'),
      );
      final requestBody = String.fromCharCodes(
        request.bodyBytes,
      );
      expect(requestBody, contains('name="target_text"'));
      expect(requestBody, contains(pronunciationReferenceText));
      expect(requestBody, contains('name="audio"'));
      expect(requestBody, contains('filename="pronunciation.wav"'));

      return http.Response(
        jsonEncode({
          'overall_score': 91,
          'score': 91,
          'target_text': pronunciationReferenceText,
          'transcript': 'practice makes perfect every single day',
          'words': [
            {
              'word': 'Practice',
              'ipa': '/ˈpræktɪs/',
              'score': 100,
              'status': 'correct',
            },
          ],
          'summary': {
            'total_words': 1,
            'correct_count': 1,
            'warning_count': 0,
            'error_count': 0,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = PronunciationService(
      client: client,
      apiBaseUri: Uri.parse('http://127.0.0.1:8000'),
    );
    addTearDown(client.close);

    final result = await service.evaluate(
      wavAudio: pcm16ToWav(Uint8List.fromList([0, 0])),
      targetText: pronunciationReferenceText,
    );

    expect(result.score, 91);
    expect(result.words.single.status, PronunciationWordStatus.correct);
  });

  testWidgets('shows the reference sentence, IPA, and recording control', (
    tester,
  ) async {
    final service = PronunciationService(
      client: MockClient((_) async => http.Response('{}', 200)),
      apiBaseUri: Uri.parse('http://127.0.0.1:8000'),
    );
    addTearDown(service.close);
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: PronunciationScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luyện phát âm AI'), findsOneWidget);
    expect(find.text(pronunciationReferenceText), findsOneWidget);
    expect(find.text(pronunciationReferenceIpa), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
