import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int? selectedOption;
  int score = 0;
  bool finished = false;

  @override
  Widget build(BuildContext context) {
    final questions = context.watch<StudyProvider>().quizQuestions;
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Chưa có câu hỏi Quiz')));
    }

    if (finished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kết Quả Quiz')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Điểm của bạn: $score / ${questions.length}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {
                  index = 0;
                  selectedOption = null;
                  score = 0;
                  finished = false;
                }),
                child: const Text('Làm lại'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[index];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz (${index + 1}/${questions.length})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(q.options.length, (i) {
              return RadioListTile<int>(
                value: i,
                groupValue: selectedOption,
                title: Text(q.options[i]),
                onChanged: (val) => setState(() => selectedOption = val),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedOption == null
                  ? null
                  : () {
                      if (selectedOption == q.correctIndex) score++;
                      if (index + 1 < questions.length) {
                        setState(() {
                          index++;
                          selectedOption = null;
                        });
                      } else {
                        setState(() => finished = true);
                      }
                    },
              child: Text(index + 1 < questions.length ? 'Câu tiếp theo' : 'Nộp bài'),
            ),
          ],
        ),
      ),
    );
  }
}
