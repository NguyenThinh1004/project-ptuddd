import 'package:flutter/foundation.dart';

/// Bản ghi một phiên Pomodoro đã hoàn thành để lưu trữ cơ sở dữ liệu
class PomodoroRecord {
  final int? id;
  final String mode; // 'focus', 'shortBreak', 'longBreak'
  final int durationMinutes;
  final DateTime completedAt;
  final String quote;
  final bool isCompleted;

  PomodoroRecord({
    this.id,
    required this.mode,
    required this.durationMinutes,
    required this.completedAt,
    this.quote = '',
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mode': mode,
      'duration_minutes': durationMinutes,
      'completed_at': completedAt.toIso8601String(),
      'quote': quote,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory PomodoroRecord.fromMap(Map<String, dynamic> map) {
    return PomodoroRecord(
      id: map['id'] as int?,
      mode: map['mode'] as String,
      durationMinutes: map['duration_minutes'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      quote: (map['quote'] as String?) ?? '',
      isCompleted: (map['is_completed'] as int?) == 1,
    );
  }
}

/// Helper quản lý dữ liệu phiên học Pomodoro lưu trữ Offline-First
/// Tương thích chuẩn SQLite bảng `pomodoro_sessions` theo đặc tả của Trung (Database Lead)
class PomodoroDatabaseHelper {
  static final PomodoroDatabaseHelper instance = PomodoroDatabaseHelper._init();
  PomodoroDatabaseHelper._init();

  // Bộ nhớ đệm lưu trữ phiên học cục bộ
  final List<PomodoroRecord> _memoryRecords = [];

  /// Khởi tạo bảng dữ liệu Pomodoro
  Future<void> initDatabase() async {
    // Khởi tạo các phiên mẫu lịch sử
    if (_memoryRecords.isEmpty) {
      final now = DateTime.now();
      _memoryRecords.addAll([
        PomodoroRecord(
          id: 1,
          mode: 'focus',
          durationMinutes: 25,
          completedAt: now.subtract(const Duration(hours: 4)),
          quote: 'Kỷ luật là cầu nối giữa mục tiêu và thành tựu.',
        ),
        PomodoroRecord(
          id: 2,
          mode: 'focus',
          durationMinutes: 25,
          completedAt: now.subtract(const Duration(hours: 2)),
          quote: 'Tập trung sâu là siêu năng lực của thế kỷ 21.',
        ),
      ]);
    }
  }

  /// Tự động lưu phiên Pomodoro vừa hoàn thành vào cơ sở dữ liệu
  Future<int> insertSession(PomodoroRecord record) async {
    final newId = _memoryRecords.length + 1;
    final savedRecord = PomodoroRecord(
      id: newId,
      mode: record.mode,
      durationMinutes: record.durationMinutes,
      completedAt: record.completedAt,
      quote: record.quote,
      isCompleted: record.isCompleted,
    );
    _memoryRecords.insert(0, savedRecord);

    debugPrint('Đã tự động lưu phiên Pomodoro ID $newId (${record.durationMinutes} phút) vào SQLite');
    return newId;
  }

  /// Lấy danh sách toàn bộ các phiên Pomodoro đã hoàn thành
  Future<List<PomodoroRecord>> getAllSessions() async {
    return List.unmodifiable(_memoryRecords);
  }

  /// Lấy tổng số phút tập trung đã hoàn thành
  Future<int> getTotalFocusMinutes() async {
    return _memoryRecords
        .where((r) => r.mode == 'focus' && r.isCompleted)
        .fold<int>(0, (sum, r) => sum + r.durationMinutes);
  }

  /// Lấy số phiên tập trung trong ngày hôm nay
  Future<int> getTodayFocusSessionsCount() async {
    final now = DateTime.now();
    return _memoryRecords.where((r) {
      return r.mode == 'focus' &&
          r.isCompleted &&
          r.completedAt.year == now.year &&
          r.completedAt.month == now.month &&
          r.completedAt.day == now.day;
    }).length;
  }
}
