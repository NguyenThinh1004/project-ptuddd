import 'package:flutter/foundation.dart';

/// Đại diện cho một phiên học tập đã hoàn thành
class StudySession {
  final String id;
  final String subject;
  final int minutes;
  final DateTime timestamp;
  final String note;

  StudySession({
    required this.id,
    required this.subject,
    required this.minutes,
    required this.timestamp,
    this.note = '',
  });
}

/// Bản ghi thống kê học tập cho một ngày cụ thể
class DayStudyRecord {
  final DateTime date;
  final int minutes;
  final int level; // 0 (0p), 1 (1-15p), 2 (16-30p), 3 (31-50p), 4 (>50p)
  final bool isCompleted;

  DayStudyRecord({
    required this.date,
    required this.minutes,
    required this.level,
    required this.isCompleted,
  });
}

/// Provider quản lý dữ liệu kỷ luật học tập (Discipline System) của StudyMate AI
/// Theo dõi chuỗi ngày Streak 🔥, tiến độ mục tiêu ngày, và bản đồ nhiệt Heatmap 30 ngày
class DisciplineProvider extends ChangeNotifier {
  // Chuỗi ngày học liên tục (Streak)
  int _currentStreak = 7;
  int _longestStreak = 14;

  // Mục tiêu học tập ngày (phút)
  int _dailyGoalMinutes = 30;

  // Số phút đã học hôm nay (ví dụ: 25/30 phút theo yêu cầu đề bài)
  int _todayMinutesLearned = 25;

  // Ngày đang được chọn trên dải DateSelectorStrip
  DateTime _selectedDate = DateTime.now();

  // Đánh dấu đã tăng streak trong ngày hôm nay chưa
  bool _hasIncreasedStreakToday = false;

  // Lưu trữ số phút học tập theo ngày (key dạng yyyy-MM-dd)
  final Map<String, int> _dailyStudyMinutes = {};

  // Danh sách các phiên học gần đây
  final List<StudySession> _sessions = [];

  DisciplineProvider() {
    _initializeMockData();
  }

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  int get todayMinutesLearned => _todayMinutesLearned;
  DateTime get selectedDate => _selectedDate;
  bool get hasIncreasedStreakToday => _hasIncreasedStreakToday;
  List<StudySession> get recentSessions => List.unmodifiable(_sessions);

  /// Tỷ lệ hoàn thành mục tiêu ngày hôm nay (0.0 đến 1.0+)
  double get todayProgressRate {
    if (_dailyGoalMinutes <= 0) return 0.0;
    return (_todayMinutesLearned / _dailyGoalMinutes).clamp(0.0, 1.0);
  }

  /// Phần trăm hoàn thành mục tiêu ngày hôm nay (0 đến 100+)
  int get todayProgressPercent {
    if (_dailyGoalMinutes <= 0) return 0;
    return ((_todayMinutesLearned / _dailyGoalMinutes) * 100).round();
  }

  /// Kiểm tra xem hôm nay đã hoàn thành mục tiêu đề ra chưa
  bool get isTodayGoalCompleted => _todayMinutesLearned >= _dailyGoalMinutes;

  /// Số phút còn lại để đạt mục tiêu hôm nay
  int get remainingMinutesToday {
    final remaining = _dailyGoalMinutes - _todayMinutesLearned;
    return remaining > 0 ? remaining : 0;
  }

  /// Định dạng ngày thành key yyyy-MM-dd
  static String dateToKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Khởi tạo dữ liệu giả lập ban đầu cho 30 ngày (để hiển thị Heatmap và Streak chân thực)
  void _initializeMockData() {
    final now = DateTime.now();
    final todayKey = dateToKey(now);
    _dailyStudyMinutes[todayKey] = _todayMinutesLearned;

    // Giả lập lịch sử 29 ngày trước
    // 7 ngày gần nhất duy trì đều đặn để tạo thành Streak 7 ngày
    for (int i = 1; i <= 29; i++) {
      final date = now.subtract(Duration(days: i));
      final key = dateToKey(date);

      if (i <= 6) {
        // 6 ngày gần nhất đều học trên 30 phút (đảm bảo Streak liên tục 7 ngày cùng hôm nay)
        _dailyStudyMinutes[key] = (30 + (i * 7) % 35);
      } else if (i == 7) {
        // Ngày thứ 7 trước có học 20 phút (vẫn có dữ liệu nhưng streak 7 ngày)
        _dailyStudyMinutes[key] = 20;
      } else if (i % 5 == 0) {
        // Một số ngày nghỉ học
        _dailyStudyMinutes[key] = 0;
      } else {
        // Các ngày khác có học phân bổ từ 15 đến 60 phút
        _dailyStudyMinutes[key] = (15 + (i * 11) % 45);
      }
    }

    // Thêm các phiên học mẫu hôm nay
    _sessions.add(
      StudySession(
        id: 'session_init_1',
        subject: 'Luyện Phát Âm AI',
        minutes: 15,
        timestamp: now.subtract(const Duration(hours: 3)),
        note: 'Luyện 20 từ vựng chuyên ngành CNTT',
      ),
    );
    _sessions.add(
      StudySession(
        id: 'session_init_2',
        subject: 'Thẻ Flashcards SM-2',
        minutes: 10,
        timestamp: now.subtract(const Duration(hours: 1)),
        note: 'Ôn tập 15 thẻ từ vựng Leitner',
      ),
    );
  }

  /// Tính mức độ đóng góp (Contribution Level 0 - 4) theo số phút học phong cách GitHub
  static int calculateLevel(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes <= 15) return 1;
    if (minutes <= 30) return 2;
    if (minutes <= 50) return 3;
    return 4;
  }

  /// Lấy số phút đã học của một ngày bất kỳ
  int getMinutesForDate(DateTime date) {
    final key = dateToKey(date);
    return _dailyStudyMinutes[key] ?? 0;
  }

  /// Lấy danh sách 30 ngày gần nhất để vẽ Monthly Heatmap Grid
  List<DayStudyRecord> getMonthlyHeatmapRecords([int count = 30]) {
    final List<DayStudyRecord> records = [];
    final now = DateTime.now();

    // Đi từ (count - 1) ngày trước tới hôm nay
    for (int i = count - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final minutes = getMinutesForDate(date);
      records.add(
        DayStudyRecord(
          date: date,
          minutes: minutes,
          level: calculateLevel(minutes),
          isCompleted: minutes >= _dailyGoalMinutes,
        ),
      );
    }
    return records;
  }

  /// Lấy 7 ngày trong tuần chứa ngày được chọn (dùng cho DateSelectorStrip)
  List<DateTime> getWeekDatesForSelectedDate() {
    // Tìm ngày đầu tuần (Thứ 2)
    final date = _selectedDate;
    final weekday = date.weekday; // 1 = Thứ 2, 7 = Chủ Nhật
    final monday = date.subtract(Duration(days: weekday - 1));

    return List.generate(7, (index) {
      return DateTime(monday.year, monday.month, monday.day + index);
    });
  }

  /// Chọn một ngày cụ thể trên dải ngày
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  /// Quay về ngày hôm nay
  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  /// Cập nhật mục tiêu học tập hàng ngày
  void setDailyGoalMinutes(int minutes) {
    if (minutes > 0) {
      _dailyGoalMinutes = minutes;
      notifyListeners();
    }
  }

  /// HOÀN THÀNH 1 PHIÊN HỌC (Tiêu chí nghiệm thu cốt lõi!)
  /// Khi gọi hàm này:
  /// 1. Số phút học hôm nay tăng lên tương ứng (mặc định +25 phút cho 1 phiên Pomodoro)
  /// 2. Vòng tròn tiến độ cập nhật phản ứng theo thời gian thực
  /// 3. Nếu vượt mục tiêu ngày lần đầu, điểm Streak 🔥 tự động tăng thêm 1
  /// 4. Bản đồ nhiệt Heatmap hôm nay đổi sang màu xanh đậm hơn
  void completeStudySession({
    int minutes = 25,
    String subject = 'Đồng Hồ Pomodoro',
    String note = 'Hoàn thành phiên học tập trung',
  }) {
    if (minutes <= 0) return;

    final wasGoalReachedBefore = _todayMinutesLearned >= _dailyGoalMinutes;

    // Cộng số phút học vào hôm nay
    _todayMinutesLearned += minutes;

    final now = DateTime.now();
    final todayKey = dateToKey(now);
    _dailyStudyMinutes[todayKey] = _todayMinutesLearned;

    // Thêm vào danh sách phiên học
    _sessions.insert(
      0,
      StudySession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        minutes: minutes,
        timestamp: now,
        note: note,
      ),
    );

    // Kiểm tra tự động cập nhật Streak:
    // Nếu trước phiên học chưa đạt mục tiêu mà sau phiên học đã đạt mục tiêu,
    // và hôm nay chưa tăng streak -> Tự động tăng điểm Streak!
    final isGoalReachedNow = _todayMinutesLearned >= _dailyGoalMinutes;
    if (!wasGoalReachedBefore && isGoalReachedNow && !_hasIncreasedStreakToday) {
      _currentStreak += 1;
      _hasIncreasedStreakToday = true;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    }

    // Thông báo cho tất cả widget đang lắng nghe (DisciplineProvider) cập nhật giao diện
    notifyListeners();
  }

  /// Đặt lại tiến độ hôm nay (dành cho việc test hoặc reset ngày mới)
  void resetTodayForTesting() {
    _todayMinutesLearned = 0;
    _hasIncreasedStreakToday = false;
    final now = DateTime.now();
    _dailyStudyMinutes[dateToKey(now)] = 0;
    notifyListeners();
  }
}
