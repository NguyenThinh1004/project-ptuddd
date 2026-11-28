import 'dart:math';

import '../database/database_helper.dart';
import 'sm2_service.dart';

class FlashcardCategory {
  const FlashcardCategory({
    required this.id,
    required this.name,
    required this.cardCount,
  });

  final int id;
  final String name;
  final int cardCount;

  factory FlashcardCategory.fromMap(Map<String, Object?> map) {
    return FlashcardCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      cardCount: map['card_count'] as int? ?? 0,
    );
  }
}

class StudyFlashcard {
  const StudyFlashcard({
    required this.id,
    required this.subjectId,
    required this.front,
    required this.back,
    required this.repetitions,
    required this.easeFactor,
    required this.interval,
    required this.nextReviewDate,
    this.ipa,
    this.example,
  });

  final int id;
  final int subjectId;
  final String front;
  final String back;
  final String? ipa;
  final String? example;
  final int repetitions;
  final double easeFactor;
  final int interval;
  final DateTime nextReviewDate;

  factory StudyFlashcard.fromMap(Map<String, Object?> map) {
    return StudyFlashcard(
      id: map['id'] as int,
      subjectId: map['subject_id'] as int,
      front: map['front_text'] as String,
      back: map['back_text'] as String,
      ipa: map['ipa'] as String?,
      example: map['example'] as String?,
      repetitions: map['repetitions'] as int,
      easeFactor: (map['ease_factor'] as num).toDouble(),
      interval: map['interval'] as int,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
    );
  }
}

class FlashcardQuizQuestion {
  const FlashcardQuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

abstract interface class FlashcardRepository {
  Future<List<FlashcardCategory>> getCategories();
  Future<List<StudyFlashcard>> getCards(int subjectId);
  Future<List<StudyFlashcard>> getDueCards(int subjectId);
  Future<int> createCategory(String name);
  Future<void> renameCategory(int subjectId, String name);
  Future<void> deleteCategory(int subjectId);
  Future<int> createCard({
    required int subjectId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  });
  Future<void> updateCard({
    required int cardId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  });
  Future<void> deleteCard(int cardId);
  Future<Sm2Result> reviewCard({
    required StudyFlashcard card,
    required int quality,
  });
}

class SqliteFlashcardRepository implements FlashcardRepository {
  SqliteFlashcardRepository({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper.instance;

  final DatabaseHelper _database;

  @override
  Future<List<FlashcardCategory>> getCategories() async {
    final rows = await _database.getSubjectsWithCardCounts();
    return rows
        .map((row) => FlashcardCategory.fromMap(row))
        .toList(growable: false);
  }

  @override
  Future<List<StudyFlashcard>> getCards(int subjectId) async {
    final rows = await _database.getFlashcardsForSubject(subjectId);
    return rows
        .map((row) => StudyFlashcard.fromMap(row))
        .toList(growable: false);
  }

  @override
  Future<List<StudyFlashcard>> getDueCards(int subjectId) async {
    final rows = await _database.getDueFlashcards();
    return rows
        .where((row) => row['subject_id'] == subjectId)
        .map((row) => StudyFlashcard.fromMap(row))
        .toList(growable: false);
  }

  @override
  Future<int> createCategory(String name) => _database.insertSubject(name);

  @override
  Future<void> renameCategory(int subjectId, String name) {
    return _database.updateSubject(subjectId: subjectId, name: name);
  }

  @override
  Future<void> deleteCategory(int subjectId) {
    return _database.deleteSubject(subjectId);
  }

  @override
  Future<int> createCard({
    required int subjectId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  }) {
    return _database.insertFlashcard(
      subjectId: subjectId,
      front: front,
      back: back,
      ipa: ipa,
      example: example,
    );
  }

  @override
  Future<void> updateCard({
    required int cardId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  }) {
    return _database.updateFlashcard(
      flashcardId: cardId,
      front: front,
      back: back,
      ipa: ipa,
      example: example,
    );
  }

  @override
  Future<void> deleteCard(int cardId) {
    return _database.deleteFlashcard(cardId);
  }

  @override
  Future<Sm2Result> reviewCard({
    required StudyFlashcard card,
    required int quality,
  }) {
    return _database.reviewFlashcard(
      flashcardId: card.id,
      quality: quality,
    );
  }
}

List<FlashcardQuizQuestion> buildFlashcardQuiz(
  List<StudyFlashcard> cards, {
  Random? random,
}) {
  final cardsByAnswer = <String, StudyFlashcard>{};
  for (final card in cards) {
    final answer = card.back.trim();
    if (answer.isNotEmpty) {
      cardsByAnswer.putIfAbsent(answer.toLowerCase(), () => card);
    }
  }

  final uniqueCards = cardsByAnswer.values.toList()..shuffle(random);
  if (uniqueCards.length < 4) return const [];

  return uniqueCards.map((card) {
    final distractors = uniqueCards
        .where((candidate) => candidate.id != card.id)
        .map((candidate) => candidate.back)
        .toList()
      ..shuffle(random);
    final options = [card.back, ...distractors.take(3)]..shuffle(random);
    return FlashcardQuizQuestion(
      prompt: '“${card.front}” có nghĩa là gì?',
      options: options,
      correctIndex: options.indexOf(card.back),
      explanation: card.example?.isNotEmpty == true
          ? '${card.back}\n${card.example}'
          : card.back,
    );
  }).toList(growable: false);
}
