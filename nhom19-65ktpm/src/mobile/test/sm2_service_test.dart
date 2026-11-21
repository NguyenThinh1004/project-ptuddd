
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/sm2_service.dart';

void main() {
  final testDate = DateTime(2026, 11, 22);

  group('SM-2 Algorithm Tests', () {

    // TEST 1: Danh gia De - on sau 6 ngay
    test('Easy: review after 6 days', () {
      final result = Sm2Service.calculate(
        quality: 5,
        repetitions: 0,
        easeFactor: 2.5,
        interval: 0,
        reviewDate: testDate,
      );

      expect(result.nextInterval, 6);
      expect(result.repetitions, 1);
      expect(result.nextReviewDate, DateTime(2026, 11, 28));
    });

    // TEST 2: Danh gia Kho - on lai ngay mai
    test('Hard: review tomorrow', () {
      final result = Sm2Service.calculate(
        quality: 2,
        repetitions: 3,
        easeFactor: 2.5,
        interval: 15,
        reviewDate: testDate,
      );

      expect(result.nextInterval, 1);
      expect(result.repetitions, 0);
      expect(result.nextReviewDate, DateTime(2026, 11, 23));
    });

    // TEST 3: Danh gia Vua - on sau 1 ngay
    test('Medium: first review after 1 day', () {
      final result = Sm2Service.calculate(
        quality: 3,
        repetitions: 0,
        easeFactor: 2.5,
        interval: 0,
        reviewDate: testDate,
      );

      expect(result.nextInterval, 1);
      expect(result.repetitions, 1);
    });

    // TEST 4: Lan on thanh cong thu hai
    test('Second successful review: 6 days', () {
      final result = Sm2Service.calculate(
        quality: 4,
        repetitions: 1,
        easeFactor: 2.5,
        interval: 1,
        reviewDate: testDate,
      );

      expect(result.nextInterval, 6);
      expect(result.repetitions, 2);
    });

    // TEST 5: Tang khoang cach on tap
    test('Later reviews: increase interval', () {
      final result = Sm2Service.calculate(
        quality: 4,
        repetitions: 2,
        easeFactor: 2.5,
        interval: 6,
        reviewDate: testDate,
      );

      expect(result.nextInterval, 15);
      expect(result.repetitions, 3);
    });

    // TEST 6: He so de nho khong duoi 1.3
    test('Ease factor minimum is 1.3', () {
      final result = Sm2Service.calculate(
        quality: 3,
        repetitions: 0,
        easeFactor: 1.35,
        interval: 0,
        reviewDate: testDate,
      );

      expect(result.easeFactor, 1.3);
    });

    // TEST 7: Quality ngoai pham vi
    test('Invalid quality throws error', () {
      expect(
        () => Sm2Service.calculate(
          quality: 6,
          repetitions: 0,
          easeFactor: 2.5,
          interval: 0,
        ),
        throwsRangeError,
      );
    });

    // TEST 8: Kiem tra chuyen danh gia
    test('Convert ratings to quality', () {
      expect(
        Sm2Service.qualityFromRating(ReviewRating.hard),
        2,
      );
      expect(
        Sm2Service.qualityFromRating(ReviewRating.medium),
        3,
      );
      expect(
        Sm2Service.qualityFromRating(ReviewRating.easy),
        5,
      );
    });

    // TEST 9: Khoang cach khong duoc am
    test('Negative interval throws error', () {
      expect(
        () => Sm2Service.calculate(
          quality: 5,
          repetitions: 0,
          easeFactor: 2.5,
          interval: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
