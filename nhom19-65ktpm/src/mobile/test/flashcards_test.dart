import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/flashcard_repository.dart';
import 'package:mobile/services/sm2_service.dart';
import 'package:mobile/views/flashcards/flashcards_screen.dart';
import 'package:mobile/views/flashcards/flashcard_quiz_screen.dart';
import 'package:mobile/views/flashcards/flashcard_review_screen.dart';

void main() {
  group('Flashcard quiz', () {
    test('creates four distinct choices and identifies the correct answer', () {
      final cards = _sampleCards();
      final questions = buildFlashcardQuiz(cards);

      expect(questions, hasLength(4));
      for (final question in questions) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4));
        expect(
          question.options[question.correctIndex],
          cards
              .singleWhere((card) => question.prompt.contains(card.front))
              .back,
        );
      }
    });

    test('does not generate a quiz with fewer than four distinct answers', () {
      final cards = _sampleCards()
          .map(
            (card) => StudyFlashcard(
              id: card.id,
              subjectId: card.subjectId,
              front: card.front,
              back: 'Same definition',
              repetitions: card.repetitions,
              easeFactor: card.easeFactor,
              interval: card.interval,
              nextReviewDate: card.nextReviewDate,
            ),
          )
          .toList();

      expect(buildFlashcardQuiz(cards), isEmpty);
    });

    testWidgets('shows immediate feedback after selecting a quiz answer',
        (tester) async {
      final repository = _FakeFlashcardRepository(cards: _sampleCards());
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardQuizScreen(
            category: _category,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Câu 1 / 4'), findsOneWidget);
      final firstOption = find.byType(OutlinedButton).first;
      await tester.tap(firstOption);
      await tester.pump();

      expect(
        find.textContaining('Chính xác!').evaluate().isNotEmpty ||
            find.textContaining('Chưa đúng.').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Câu tiếp theo'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(4));
    });
  });

  testWidgets('flip card enables SM-2 rating and saves the selected quality',
      (tester) async {
    final repository = _FakeFlashcardRepository(cards: [_sampleCards().first]);
    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardReviewScreen(
          category: _category,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final easyButton = find.widgetWithText(OutlinedButton, 'Dễ');
    expect(tester.widget<OutlinedButton>(easyButton).onPressed, isNull);

    await tester.tap(find.text('word 1'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn nhớ thẻ này đến mức nào?'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(easyButton).onPressed, isNotNull);
    await tester.tap(easyButton);
    await tester.pumpAndSettle();

    expect(repository.lastReviewQuality, 5);
    expect(find.text('Bạn đã ôn hết thẻ đến hạn!'), findsOneWidget);
  });

  testWidgets('can add a flashcard to a subject from the dashboard flow',
      (tester) async {
    final repository = _FakeFlashcardRepository(cards: []);
    await tester.pumpWidget(
      MaterialApp(home: FlashcardsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quản lý thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Bộ thẻ đang trống'), findsOneWidget);

    await tester.tap(find.text('Thêm thẻ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mặt trước: từ / khái niệm'),
      'focus',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mặt sau: định nghĩa'),
      'concentrated attention',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('focus'), findsOneWidget);
    expect(find.text('concentrated attention'), findsOneWidget);
    expect(repository.cards, hasLength(1));
  });

  testWidgets('can create a subject from the Flashcards screen',
      (tester) async {
    final repository = _FakeFlashcardRepository(cards: []);
    await tester.pumpWidget(
      MaterialApp(home: FlashcardsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm môn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Biology');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Biology'), findsOneWidget);
    expect(repository.categories, hasLength(2));
  });
}

const _category = FlashcardCategory(id: 1, name: 'English', cardCount: 4);

List<StudyFlashcard> _sampleCards() {
  return List.generate(
    4,
    (index) => StudyFlashcard(
      id: index + 1,
      subjectId: _category.id,
      front: 'word ${index + 1}',
      back: 'definition ${index + 1}',
      ipa: '/wɜːd/',
      example: 'Example ${index + 1}',
      repetitions: 0,
      easeFactor: 2.5,
      interval: 0,
      nextReviewDate: DateTime(2020),
    ),
  );
}

class _FakeFlashcardRepository implements FlashcardRepository {
  _FakeFlashcardRepository({required this.cards});

  final List<StudyFlashcard> cards;
  final List<FlashcardCategory> categories = [_category];
  int? lastReviewQuality;
  int _nextCardId = 5;

  @override
  Future<List<FlashcardCategory>> getCategories() async => categories
      .map(
        (category) => FlashcardCategory(
          id: category.id,
          name: category.name,
          cardCount: category.id == _category.id ? cards.length : 0,
        ),
      )
      .toList();

  @override
  Future<List<StudyFlashcard>> getCards(int subjectId) async => cards;

  @override
  Future<List<StudyFlashcard>> getDueCards(int subjectId) async => cards;

  @override
  Future<int> createCategory(String name) async {
    const categoryId = 2;
    categories.add(
      FlashcardCategory(id: categoryId, name: name, cardCount: 0),
    );
    return categoryId;
  }

  @override
  Future<void> renameCategory(int subjectId, String name) async {
    final index = categories.indexWhere((category) => category.id == subjectId);
    if (index >= 0) {
      categories[index] = FlashcardCategory(
        id: subjectId,
        name: name,
        cardCount: categories[index].cardCount,
      );
    }
  }

  @override
  Future<void> deleteCategory(int subjectId) async {
    categories.removeWhere((category) => category.id == subjectId);
  }

  @override
  Future<int> createCard({
    required int subjectId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  }) async {
    final cardId = _nextCardId++;
    cards.add(
      StudyFlashcard(
        id: cardId,
        subjectId: subjectId,
        front: front,
        back: back,
        ipa: ipa,
        example: example,
        repetitions: 0,
        easeFactor: 2.5,
        interval: 0,
        nextReviewDate: DateTime(2020),
      ),
    );
    return cardId;
  }

  @override
  Future<void> updateCard({
    required int cardId,
    required String front,
    required String back,
    String? ipa,
    String? example,
  }) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index < 0) return;
    final card = cards[index];
    cards[index] = StudyFlashcard(
      id: card.id,
      subjectId: card.subjectId,
      front: front,
      back: back,
      ipa: ipa,
      example: example,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      interval: card.interval,
      nextReviewDate: card.nextReviewDate,
    );
  }

  @override
  Future<void> deleteCard(int cardId) async {
    cards.removeWhere((card) => card.id == cardId);
  }

  @override
  Future<Sm2Result> reviewCard({
    required StudyFlashcard card,
    required int quality,
  }) async {
    lastReviewQuality = quality;
    return Sm2Service.calculate(
      quality: quality,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      interval: card.interval,
    );
  }
}
