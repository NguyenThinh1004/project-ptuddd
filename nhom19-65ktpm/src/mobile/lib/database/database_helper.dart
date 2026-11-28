
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../services/sm2_service.dart';

class DatabaseHelper {
  // ==========================================
  // 1. SINGLETON & DATABASE CONFIGURATION
  // ==========================================

  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const int _databaseVersion = 2;
  static const String _databaseName = 'studymate.db';

  Database? _database;

  // ==========================================
  // 2. MO VA KHOI TAO DATABASE
  // ==========================================

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        // Bat rang buoc khoa ngoai
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  // ==========================================
  // 3. TAO CAC BANG SQLITE
  // ==========================================

  Future<void> _onCreate(Database db, int version) async {
    // BANG 1: SUBJECTS
    // Quan ly danh sach mon hoc

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // BANG 2: FLASHCARDS
    // Quan ly the ghi nho va lich on tap SM-2

    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        front_text TEXT NOT NULL,
        back_text TEXT NOT NULL,
        repetition_level INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval INTEGER NOT NULL DEFAULT 0,
        next_review_date TEXT NOT NULL,
        FOREIGN KEY (subject_id)
          REFERENCES subjects(id)
          ON DELETE CASCADE
      )
    ''');

    // BANG 3: POMODORO SESSIONS
    // Luu lich su cac phien hoc tap

    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        duration INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // BANG 4: DAILY HABITS
    // Theo doi thoi quen hoc tap hang ngay

    await db.execute('''
      CREATE TABLE daily_habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_date TEXT NOT NULL UNIQUE,
        study_minutes INTEGER NOT NULL DEFAULT 0,
        is_goal_completed INTEGER NOT NULL DEFAULT 0,
        streak_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // INDEX: Tim flashcards theo ngay on tap

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_flashcards_review
      ON flashcards(next_review_date)
    ''');

    // INDEX: Tim flashcards theo mon hoc

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_flashcards_subject
      ON flashcards(subject_id)
    ''');

    // Them du lieu mau khi tao database lan dau
    await _seedData(db);
  }

  // ==========================================
  // 4. DATABASE MIGRATION
  // ==========================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migration Version 1 -> Version 2

    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_flashcards_subject
        ON flashcards(subject_id)
      ''');
    }

    // Cac migration Version 3 tro len
    // se duoc bo sung tai day.
  }

  // ==========================================
  // 5. THEM DU LIEU MAU (SEED DATA)
  // ==========================================

  Future<void> _seedData(Database db) async {
    // Tao mon hoc English

    final englishId = await db.insert('subjects', {
      'name': 'English',
      'color': '#7C4DFF',
      'icon': 'language',
    });

    // Tao mon hoc Mathematics

    await db.insert('subjects', {
      'name': 'Mathematics',
      'color': '#2196F3',
      'icon': 'calculate',
    });

    // 10 flashcards tieng Anh

    final words = <List<String>>[
      ['Apple', 'Qua tao'],
      ['Book', 'Quyen sach'],
      ['School', 'Truong hoc'],
      ['Teacher', 'Giao vien'],
      ['Student', 'Hoc sinh'],
      ['Computer', 'May tinh'],
      ['Knowledge', 'Kien thuc'],
      ['Discipline', 'Ky luat'],
      ['Success', 'Thanh cong'],
      ['Practice', 'Luyen tap'],
    ];

    // Ngay on tap dau tien

    final today = DateTime.now()
        .toIso8601String()
        .substring(0, 10);

    for (final word in words) {
      await db.insert('flashcards', {
        'subject_id': englishId,
        'front_text': word[0],
        'back_text': word[1],
        'next_review_date': today,
      });
    }
  }

  // ==========================================
  // 6. LAY DANH SACH MON HOC
  // ==========================================

  Future<List<Map<String, Object?>>> getSubjects() async {
    final db = await database;

    return db.query(
      'subjects',
      orderBy: 'id ASC',
    );
  }

  // ==========================================
  // 7. LAY DANH SACH FLASHCARDS
  // ==========================================

  Future<List<Map<String, Object?>>> getFlashcards() async {
    final db = await database;

    return db.query(
      'flashcards',
      orderBy: 'id ASC',
    );
  }

  // ==========================================
  // 8. LAY FLASHCARDS DEN HAN ON TAP
  // ==========================================

  Future<List<Map<String, Object?>>> getDueFlashcards({
    DateTime? date,
  }) async {
    final db = await database;

    // Mac dinh lay ngay hien tai
    final today = (date ?? DateTime.now())
        .toIso8601String()
        .substring(0, 10);

    // Lay cac the co ngay on <= hom nay
    return db.query(
      'flashcards',
      where: 'next_review_date <= ?',
      whereArgs: [today],
      orderBy: 'next_review_date ASC, id ASC',
    );
  }

  // ==========================================
  // 9. DANH GIA FLASHCARD BANG THUAT TOAN SM-2
  // ==========================================

  Future<Sm2Result> reviewFlashcard({
    required int flashcardId,
    required int quality,
    DateTime? reviewDate,
  }) async {
    final db = await database;

    // Su dung transaction de dam bao
    // viec doc va cap nhat du lieu nhat quan

    return db.transaction((txn) async {
      // 1. Lay flashcard theo ID

      final cards = await txn.query(
        'flashcards',
        where: 'id = ?',
        whereArgs: [flashcardId],
        limit: 1,
      );

      // Kiem tra flashcard co ton tai khong

      if (cards.isEmpty) {
        throw StateError(
          'Khong tim thay flashcard ID: $flashcardId',
        );
      }

      final card = cards.first;

      // 2. Lay trang thai SM-2 hien tai

      final repetitions = card['repetitions'] as int;

      final easeFactor =
          (card['ease_factor'] as num).toDouble();

      final interval = card['interval'] as int;

      // 3. Tinh toan lich on tap bang SM-2

      final result = Sm2Service.calculate(
        quality: quality,
        repetitions: repetitions,
        easeFactor: easeFactor,
        interval: interval,
        reviewDate: reviewDate,
      );

      // 4. Chuyen ngay on tiep theo sang TEXT
      // Dinh dang YYYY-MM-DD

      final nextReviewDate = result.nextReviewDate
          .toIso8601String()
          .substring(0, 10);

      // 5. Cap nhat trang thai flashcard vao SQLite

      await txn.update(
        'flashcards',
        {
          'repetitions': result.repetitions,
          'ease_factor': result.easeFactor,
          'interval': result.nextInterval,
          'next_review_date': nextReviewDate,
        },
        where: 'id = ?',
        whereArgs: [flashcardId],
      );

      // 6. Tra ve ket qua tinh toan SM-2

      return result;
    });
  }

  // ==========================================
  // 10. DONG DATABASE
  // ==========================================

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
