import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_models.dart';
import '../providers/study_provider.dart';

class Flashcard3DScreen extends StatelessWidget {
  const Flashcard3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final card = provider.currentCard;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards Lật 3D')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: card == null
            ? const Center(child: Text('Chưa có thẻ ghi nhớ'))
            : Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: provider.toggleFlip,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: provider.isFlipped ? pi : 0,
                        ),
                        duration: const Duration(milliseconds: 450),
                        builder: (context, angle, child) {
                          final showBack = angle >= pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(angle),
                            child: Card(
                              elevation: 4,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..rotateY(showBack ? pi : 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          showBack ? 'MẶT SAU' : 'MẶT TRƯỚC (Chạm để lật)',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          showBack ? card.back : card.front,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!showBack && card.ipa != null) ...[
                                          const SizedBox(height: 8),
                                          Text(card.ipa!, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn mức độ ghi nhớ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.rateCard(RecallRating.hard),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                          child: const Text('Khó'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.rateCard(RecallRating.medium),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
                          child: const Text('Vừa'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.rateCard(RecallRating.easy),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                          child: const Text('Dễ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: provider.isGeneratingCards
                        ? null
                        : () => provider.generateAiCards('Sinh thêm thẻ ôn tập', card.subjectId),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(provider.isGeneratingCards ? 'Đang sinh...' : 'Sinh thêm Flashcard bằng AI'),
                  ),
                ],
              ),
      ),
    );
  }
}
