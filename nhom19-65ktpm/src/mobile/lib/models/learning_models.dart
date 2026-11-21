enum WordAccuracy { correct, close, wrong }

class WordPronunciationResult {
  final String word;
  final String ipa;
  final WordAccuracy accuracy;

  WordPronunciationResult({
    required this.word,
    required this.ipa,
    required this.accuracy,
  });

  factory WordPronunciationResult.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? 'wrong').toString().toLowerCase();
    WordAccuracy acc = WordAccuracy.wrong;
    if (status == 'correct' || status == 'good') {
      acc = WordAccuracy.correct;
    } else if (status == 'close' || status == 'medium') {
      acc = WordAccuracy.close;
    }
    return WordPronunciationResult(
      word: json['word'] ?? '',
      ipa: json['ipa'] ?? '',
      accuracy: acc,
    );
  }
}

class SpeechAssessmentResult {
  final double overallScore;
  final String transcript;
  final List<WordPronunciationResult> words;

  SpeechAssessmentResult({
    required this.overallScore,
    required this.transcript,
    required this.words,
  });

  factory SpeechAssessmentResult.fromJson(Map<String, dynamic> json) {
    final rawWords = (json['words'] as List<dynamic>? ?? []);
    return SpeechAssessmentResult(
      overallScore: ((json['score'] ?? 0) as num).toDouble(),
      transcript: json['transcript'] ?? '',
      words: rawWords
          .map((e) => WordPronunciationResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

enum RecallRating { easy, medium, hard }

class FlashcardItem {
  final String id;
  final String subjectId;
  final String front;
  final String back;
  final String? ipa;
  int easeLevel;

  FlashcardItem({
    required this.id,
    required this.subjectId,
    required this.front,
    required this.back,
    this.ipa,
    this.easeLevel = 1,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class StudySubject {
  final String id;
  final String name;
  final List<String> materials;
  final List<String> notes;

  StudySubject({
    required this.id,
    required this.name,
    this.materials = const [],
    this.notes = const [],
  });
}
