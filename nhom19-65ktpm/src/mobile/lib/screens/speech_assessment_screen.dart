import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_models.dart';
import '../providers/speech_provider.dart';

class SpeechAssessmentScreen extends StatelessWidget {
  const SpeechAssessmentScreen({super.key});

  Color _colorForAccuracy(WordAccuracy acc) {
    switch (acc) {
      case WordAccuracy.correct:
        return Colors.green;
      case WordAccuracy.close:
        return Colors.orange;
      case WordAccuracy.wrong:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpeechProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Luyện Phát Âm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Câu mẫu luyện đọc:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: provider.targetSentence,
                      onChanged: provider.setTargetSentence,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: provider.speakTarget,
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Nghe chuẩn'),
                        ),
                        const SizedBox(width: 8),
                        if (provider.lastAudioPath != null)
                          OutlinedButton.icon(
                            onPressed: provider.playUserRecording,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Nghe lại giọng bạn'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: provider.waveformBars.map((amp) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 6,
                    height: 14 + amp * 56,
                    decoration: BoxDecoration(
                      color: provider.isRecording ? Colors.redAccent : Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.toggleRecording,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: provider.isRecording ? Colors.red : null,
                foregroundColor: provider.isRecording ? Colors.white : null,
              ),
              icon: Icon(provider.isRecording ? Icons.stop : Icons.mic),
              label: Text(provider.isRecording ? 'Dừng thu âm & Chấm điểm' : 'Bắt đầu thu âm'),
            ),
            const SizedBox(height: 16),
            if (provider.isAssessing) const Center(child: CircularProgressIndicator()),
            if (provider.result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm tổng quan: ${provider.result!.overallScore.toStringAsFixed(0)}/100',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Chú thích: Xanh = Chuẩn | Cam = Gần đúng | Đỏ = Sai âm'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.result!.words.map((w) {
                          final c = _colorForAccuracy(w.accuracy);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.14),
                              border: Border.all(color: c),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  w.word,
                                  style: TextStyle(color: c, fontWeight: FontWeight.bold),
                                ),
                                if (w.ipa.isNotEmpty)
                                  Text(w.ipa, style: TextStyle(fontSize: 11, color: c)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
