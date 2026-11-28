import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';

import '../../services/pronunciation_service.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key, this.service});

  final PronunciationService? service;

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  static const int _sampleRate = 16000;
  static const int _minimumRecordingBytes = _sampleRate ~/ 5 * 2;
  static const int _maximumRecordingSeconds = 30;

  late final PronunciationService _service;
  late final bool _ownsService;
  AudioRecorder? _recorder;
  FlutterTts? _textToSpeech;
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _recordingLimitTimer;
  BytesBuilder _recordedAudio = BytesBuilder(copy: false);
  List<double> _waveform = List<double>.filled(36, 0.04);
  PronunciationResult? _result;
  String? _errorMessage;
  bool _isStarting = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? PronunciationService();
  }

  @override
  void dispose() {
    _recordingLimitTimer?.cancel();
    final subscription = _audioSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    final recorder = _recorder;
    if (recorder != null) {
      unawaited(_releaseRecorder(recorder));
    }
    final textToSpeech = _textToSpeech;
    if (textToSpeech != null) {
      unawaited(_stopTextToSpeech(textToSpeech));
    }
    if (_ownsService) {
      _service.close();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isStarting || _isRecording || _isAnalyzing) return;
    setState(() {
      _isStarting = true;
      _errorMessage = null;
      _result = null;
      _recordedAudio = BytesBuilder(copy: false);
      _waveform = List<double>.filled(36, 0.04);
    });

    final recorder = AudioRecorder();
    _recorder = recorder;
    try {
      if (!await recorder.hasPermission()) {
        throw StateError(
          'Chưa được cấp quyền micro. Hãy cho phép truy cập micro rồi thử lại.',
        );
      }

      final audioStream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _audioSubscription = audioStream.listen(
        _onAudioChunk,
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Không thể tiếp tục ghi âm: $error';
            });
          }
        },
      );
      if (!mounted) {
        await _releaseRecorder(recorder);
        _recorder = null;
        return;
      }
      setState(() {
        _isStarting = false;
        _isRecording = true;
      });
      _recordingLimitTimer = Timer(
        const Duration(seconds: _maximumRecordingSeconds),
        _stopAndEvaluate,
      );
    } catch (error) {
      await _releaseRecorder(recorder);
      _recorder = null;
      if (mounted) {
        setState(() {
          _isStarting = false;
          _isRecording = false;
          _errorMessage = _errorMessageFor(error);
        });
      }
    }
  }

  void _onAudioChunk(Uint8List chunk) {
    _recordedAudio.add(chunk);
    if (chunk.length < 2) return;

    final samples = ByteData.sublistView(chunk);
    var totalAmplitude = 0.0;
    var sampleCount = 0;
    for (var offset = 0; offset + 1 < chunk.length; offset += 2) {
      totalAmplitude += samples.getInt16(offset, Endian.little).abs() / 32768;
      sampleCount++;
    }
    final amplitude = sampleCount == 0
        ? 0.04
        : (totalAmplitude / sampleCount).clamp(0.04, 1.0);

    if (mounted) {
      setState(() {
        _waveform = [..._waveform.skip(1), amplitude];
      });
    }
  }

  Future<void> _stopAndEvaluate() async {
    if (!_isRecording || _isAnalyzing) return;
    _recordingLimitTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
      _errorMessage = null;
    });

    final recorder = _recorder;
    try {
      if (recorder == null) {
        throw StateError('Không tìm thấy phiên ghi âm để xử lý.');
      }
      await recorder.stop();
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      final pcmBytes = _recordedAudio.takeBytes();
      if (pcmBytes.length < _minimumRecordingBytes) {
        throw StateError('Hãy ghi âm ít nhất 0,2 giây trước khi chấm điểm.');
      }

      final result = await _service.evaluate(
        wavAudio: pcm16ToWav(pcmBytes, sampleRate: _sampleRate),
        targetText: pronunciationReferenceText,
      );
      if (mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _errorMessageFor(error);
        });
      }
    } finally {
      _recordingLimitTimer?.cancel();
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      if (recorder != null) {
        await _releaseRecorder(recorder);
      }
      _recorder = null;
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _playReference() async {
    if (_isSpeaking || _isRecording || _isAnalyzing) return;
    final textToSpeech = _textToSpeech ??= FlutterTts();
    setState(() {
      _isSpeaking = true;
      _errorMessage = null;
    });
    try {
      await textToSpeech.setLanguage('en-US');
      await textToSpeech.setSpeechRate(0.45);
      await textToSpeech.awaitSpeakCompletion(true);
      await textToSpeech.speak(pronunciationReferenceText);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể phát giọng đọc mẫu: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _releaseRecorder(AudioRecorder recorder) async {
    try {
      await recorder.dispose();
    } catch (error) {
      debugPrint('Không thể giải phóng micro: $error');
    }
  }

  Future<void> _stopTextToSpeech(FlutterTts textToSpeech) async {
    try {
      await textToSpeech.stop();
    } catch (error) {
      debugPrint('Không thể dừng giọng đọc mẫu: $error');
    }
  }

  String _errorMessageFor(Object error) {
    if (error is PronunciationApiException) return error.message;
    if (error is StateError) return error.message;
    return 'Không thể hoàn tất luyện phát âm: $error';
  }

  Color _colorForStatus(PronunciationWordStatus status) {
    return switch (status) {
      PronunciationWordStatus.correct => const Color(0xFF059669),
      PronunciationWordStatus.warning => const Color(0xFFD97706),
      PronunciationWordStatus.error => const Color(0xFFDC2626),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Luyện phát âm AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Luyện nói tiếng Anh, nhận phản hồi theo từng từ.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildReferenceCard(theme, isDark),
                  const SizedBox(height: 16),
                  _buildRecorderCard(theme, isDark),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(theme),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _buildResultCard(theme, isDark, _result!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceCard(ThemeData theme, bool isDark) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.menu_book_rounded,
            title: 'Câu mẫu',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            pronunciationReferenceText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pronunciationReferenceIpa,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSpeaking || _isRecording || _isAnalyzing
                ? null
                : _playReference,
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
                _isSpeaking ? 'Đang phát giọng mẫu...' : 'Nghe giọng đọc mẫu'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorderCard(ThemeData theme, bool isDark) {
    final accent =
        _isRecording ? const Color(0xFFDC2626) : const Color(0xFF4F46E5);
    final status = _isAnalyzing
        ? 'ĐANG PHÂN TÍCH'
        : _isStarting
            ? 'ĐANG MỞ MICRO'
            : _isRecording
                ? 'ĐANG GHI ÂM · TỐI ĐA 30 GIÂY'
                : 'SẴN SÀNG LUYỆN TẬP';

    return _card(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.mic_none_rounded, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thu âm giọng nói của bạn',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final amplitude in _waveform)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3,
                    height: 8 + amplitude * 58,
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: _isRecording ? 0.9 : 0.32,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 72,
            height: 72,
            child: FilledButton(
              onPressed: _isStarting || _isAnalyzing
                  ? null
                  : _isRecording
                      ? _stopAndEvaluate
                      : _startRecording,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(72, 72),
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 27,
                      height: 27,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isAnalyzing
                ? 'AI đang nhận diện và so sánh âm vị...'
                : _isRecording
                    ? 'Nhấn nút đỏ để dừng và chấm điểm'
                    : _isStarting
                        ? 'Đang yêu cầu quyền truy cập micro'
                        : 'Nhấn micro để bắt đầu đọc câu mẫu',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    ThemeData theme,
    bool isDark,
    PronunciationResult result,
  ) {
    final ipaText = result.words
        .map((word) => word.ipa)
        .where((ipa) => ipa.isNotEmpty)
        .join(' ');

    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Kết quả phân tích AI',
                  color: theme.colorScheme.primary,
                ),
              ),
              _buildScoreBadge(result.score),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Độ chính xác từng từ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 8,
            children: [
              for (var index = 0; index < result.words.length; index++)
                _buildWordChip(
                    result.words[index], index == result.words.length - 1),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'IPA: ${ipaText.isEmpty ? pronunciationReferenceIpa : ipaText}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'serif',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildLegend('Chuẩn xác', const Color(0xFF059669)),
              _buildLegend('Gần đúng', const Color(0xFFD97706)),
              _buildLegend('Cần luyện thêm', const Color(0xFFDC2626)),
            ],
          ),
          if (result.transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
            Text(
              'AI nghe được',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              result.transcript,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    final normalizedScore = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: normalizedScore,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),
          Text(
            '${score.round()}%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(PronunciationWordResult result, bool isLast) {
    final color = _colorForStatus(result.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '${result.word}${isLast ? '.' : ''}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: child,
    );
  }
}
