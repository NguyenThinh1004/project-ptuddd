
enum ReviewRating {
  hard,
  medium,
  easy,
}

class Sm2Result {
  final int repetitions;
  final double easeFactor;
  final int nextInterval;
  final DateTime nextReviewDate;

  const Sm2Result({
    required this.repetitions,
    required this.easeFactor,
    required this.nextInterval,
    required this.nextReviewDate,
  });
}

class Sm2Service {
  // Chuyen danh gia thanh quality 0-5
  static int qualityFromRating(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.hard:
        return 2;
      case ReviewRating.medium:
        return 3;
      case ReviewRating.easy:
        return 5;
    }
  }

  static Sm2Result calculate({
    required int quality,
    required int repetitions,
    required double easeFactor,
    required int interval,
    DateTime? reviewDate,
  }) {
    if (quality < 0 || quality > 5) {
      throw RangeError.range(quality, 0, 5, 'quality');
    }

    if (repetitions < 0 || interval < 0) {
      throw ArgumentError(
        'Repetitions va interval phai >= 0',
      );
    }

    if (!easeFactor.isFinite || easeFactor < 1.3) {
      throw ArgumentError(
        'Ease factor phai >= 1.3',
      );
    }

    int nextRepetitions;
    int nextInterval;
    double nextEaseFactor = easeFactor;

    if (quality < 3) {
      // Kho: on lai vao ngay hom sau
      nextRepetitions = 0;
      nextInterval = 1;
    } else {
      // Cap nhat he so de nho theo SM-2
      final difference = 5 - quality;

      nextEaseFactor = easeFactor +
          0.1 -
          difference * (0.08 + difference * 0.02);

      if (nextEaseFactor < 1.3) {
        nextEaseFactor = 1.3;
      }

      nextRepetitions = repetitions + 1;

      if (repetitions == 0) {
        // Bien the theo yeu cau Issue #5
        // De: 6 ngay, Vua: 1 ngay
        nextInterval = quality == 5 ? 6 : 1;
      } else if (repetitions == 1 && interval < 6) {
        nextInterval = 6;
      } else {
        nextInterval =
            (interval * nextEaseFactor).round();
      }
    }

    final date = reviewDate ?? DateTime.now();

    final nextReviewDate = DateTime(
      date.year,
      date.month,
      date.day + nextInterval,
    );

    return Sm2Result(
      repetitions: nextRepetitions,
      easeFactor: nextEaseFactor,
      nextInterval: nextInterval,
      nextReviewDate: nextReviewDate,
    );
  }
}
