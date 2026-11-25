
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton: Chi su dung mot DatabaseHelper
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  // Database Version 2
  static const int _databaseVersion = 2;
  static const String _databaseName = 'studymate.db';

  Database? _database;

  // ==========================================
  // 1. MO VA KHOI TAO DATABASE
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
  // 2. TAO CAC BANG KHI CHAY LAN DAU
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
    // Luu lich su phien hoc tap
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

    // INDEX 1: Tim flashcards theo ngay on tap
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_flashcards_review
      ON flashcards(next_review_date)
    ''');

    // INDEX 2: Tim flashcards theo mon hoc
    // Bo sung trong Database Version 2
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_flashcards_subject
      ON flashcards(subject_id)
    ''');

    // Tu dong them du lieu mau lan dau
    await _seedData(db);
  }

  // ==========================================
  // 3. NANG CAP DATABASE (MIGRATION)
  // ==========================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Nang cap Version 1 -> Version 2
    if (oldVersion < 2 && newVersion >= 2) {
      // Tao index moi, khong xoa bang va du lieu
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_flashcards_subject
        ON flashcards(subject_id)
      ''');
    }

    // Migration cho Version 3 tro len
    // se duoc bo sung tai day trong tuong lai.
  }

  // ==========================================
  // 4. THEM DU LIEU MAU (SEED DATA)
  // ==========================================

  Future<void> _seedData(Database db) async {
    // Tao mon hoc tieng Anh
    final englishId = await db.insert('subjects', {
      'name': 'English',
      'color': '#7C4DFF',
      'icon': 'language',
    });

    // Tao mon hoc Toan
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

    // Ngay on tap dau tien la ngay hien tai
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
  // 5. TRUY VAN DANH SACH MON HOC
  // ==========================================

  Future<List<Map<String, Object?>>> getSubjects() async {
    final db = await database;

    return db.query(
      'subjects',
      orderBy: 'id ASC',
    );
  }

  // ==========================================
  // 6. TRUY VAN DANH SACH FLASHCARDS
  // ==========================================

  Future<List<Map<String, Object?>>> getFlashcards() async {
    final db = await database;

    return db.query(
      'flashcards',
      orderBy: 'id ASC',
    );
  }

  // ==========================================
  // 7. DONG DATABASE
  // ==========================================

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
