
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const int _databaseVersion = 1;
  static const String _databaseName = 'studymate.db';

  Database? _database;

  // Mo database, neu chua co thi tu dong tao
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
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bang mon hoc
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // 2. Bang flashcards
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

    // 3. Bang lich su Pomodoro
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        duration INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Bang thoi quen hoc tap
    await db.execute('''
      CREATE TABLE daily_habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_date TEXT NOT NULL UNIQUE,
        study_minutes INTEGER NOT NULL DEFAULT 0,
        is_goal_completed INTEGER NOT NULL DEFAULT 0,
        streak_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_flashcards_review
      ON flashcards(next_review_date)
    ''');

    // Them du lieu mau lan dau
    await _seedData(db);
  }

  // Xu ly migration khi nang phien ban database
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Database hien tai la version 1.
    // Khi thay doi schema, tang _databaseVersion
    // va bo sung migration tai day.
  }

  Future<void> _seedData(Database db) async {
    // Tao 2 mon hoc mau
    final englishId = await db.insert('subjects', {
      'name': 'English',
      'color': '#7C4DFF',
      'icon': 'language',
    });

    await db.insert('subjects', {
      'name': 'Mathematics',
      'color': '#2196F3',
      'icon': 'calculate',
    });

    // 10 flashcards tieng Anh mau
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

    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (final word in words) {
      await db.insert('flashcards', {
        'subject_id': englishId,
        'front_text': word[0],
        'back_text': word[1],
        'next_review_date': today,
      });
    }
  }

  // Lay danh sach mon hoc
  Future<List<Map<String, Object?>>> getSubjects() async {
    final db = await database;
    return db.query('subjects', orderBy: 'id ASC');
  }

  // Lay danh sach flashcards
  Future<List<Map<String, Object?>>> getFlashcards() async {
    final db = await database;
    return db.query('flashcards', orderBy: 'id ASC');
  }

  // Dong ket noi database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
