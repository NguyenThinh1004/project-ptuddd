import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/pomodoro_alarm_player.dart';
import '../services/pomodoro_database_helper.dart';
import 'discipline_provider.dart';

/// Các chế độ đếm giờ của Pomodoro
enum PomodoroMode {
  focus, // Tập trung (mặc định 25 phút)
  shortBreak, // Nghỉ ngắn (mặc định 5 phút)
  longBreak, // Nghỉ dài (mặc định 15 phút)
}

/// Provider quản lý toàn bộ trạng thái đồng hồ tập trung Focus Pomodoro
/// Đếm ngược chính xác từng giây, khóa xao nhãng, chuông báo, và lưu SQLite
class PomodoroProvider extends ChangeNotifier {
  // Cấu hình thời lượng mặc định (phút)
  int _focusDurationMinutes = 25;
  int _shortBreakDurationMinutes = 5;
  int _longBreakDurationMinutes = 15;
  int _longBreakInterval = 4; // Sau 4 phiên tập trung thì nghỉ dài

  // Trạng thái đếm giờ
  PomodoroMode _currentMode = PomodoroMode.focus;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;
  final PomodoroAlarmPlayer _alarmPlayer;

  // Số phiên tập trung đã hoàn thành
  int _completedSessionsCount = 2; // Giả lập đã có 2 phiên trước đó
  int _totalFocusMinutesToday = 50;

  // Chế độ khóa xao nhãng (Distraction Lock Mode) & Âm thanh
  bool _isDistractionLockEnabled = false;
  bool _isSoundEnabled = true;

  // Liên kết tùy chọn với DisciplineProvider để tự động tăng Streak và Heatmap
  DisciplineProvider? _disciplineProvider;

  // Danh sách các câu trích dẫn truyền cảm hứng học tập sâu
  static const List<String> _inspirationalQuotes = [
    'Kỷ luật là cầu nối giữa mục tiêu và thành tựu. — Jim Rohn',
    'Tập trung sâu là siêu năng lực của thế kỷ 21. — Cal Newport',
    'Một phiên 25 phút tập trung trọn vẹn đáng giá hơn cả ngày xao nhãng.',
    'Bí quyết của người xuất chúng là kiên định làm những việc nhỏ mỗi ngày.',
    'Ngọn lửa kỷ luật hôm nay là thành công rực rỡ ngày mai. 🔥',
    'Đừng nhìn đồng hồ, hãy làm như nó: Luôn tiến về phía trước. — Sam Levenson',
    'Mỗi phút bạn chống lại sự xao nhãng là một phút bạn chiến thắng chính mình.',
  ];
  int _quoteIndex = 0;

  PomodoroProvider({
    DisciplineProvider? disciplineProvider,
    PomodoroAlarmPlayer? alarmPlayer,
  })  : _disciplineProvider = disciplineProvider,
        _alarmPlayer = alarmPlayer ?? AssetPomodoroAlarmPlayer() {
    _resetTimeToCurrentMode();
    PomodoroDatabaseHelper.instance.initDatabase();
  }

  // Getters
  PomodoroMode get currentMode => _currentMode;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get focusDurationMinutes => _focusDurationMinutes;
  int get shortBreakDurationMinutes => _shortBreakDurationMinutes;
  int get longBreakDurationMinutes => _longBreakDurationMinutes;
  int get longBreakInterval => _longBreakInterval;
  int get completedSessionsCount => _completedSessionsCount;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
  bool get isDistractionLockEnabled => _isDistractionLockEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  String get currentQuote =>
      _inspirationalQuotes[_quoteIndex % _inspirationalQuotes.length];

  /// Tiến độ từ 0.0 (vừa bắt đầu) đến 1.0 (kết thúc đếm ngược)
  double get progressRate {
    if (_totalSeconds <= 0) return 0.0;
    return (1.0 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0);
  }

  /// Chuỗi hiển thị phút:giây định dạng mm:ss (Ví dụ: "25:00", "04:32")
  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Tên chế độ tiếng Việt hiển thị
  String get modeTitle {
    switch (_currentMode) {
      case PomodoroMode.focus:
        return 'Phiên Tập Trung';
      case PomodoroMode.shortBreak:
        return 'Nghỉ Ngắn';
      case PomodoroMode.longBreak:
        return 'Nghỉ Dài';
    }
  }

  /// Gán DisciplineProvider để đồng bộ dữ liệu thời gian thực
  void updateDisciplineProvider(DisciplineProvider discipline) {
    _disciplineProvider = discipline;
  }

  void _resetTimeToCurrentMode() {
    int minutes;
    switch (_currentMode) {
      case PomodoroMode.focus:
        minutes = _focusDurationMinutes;
        break;
      case PomodoroMode.shortBreak:
        minutes = _shortBreakDurationMinutes;
        break;
      case PomodoroMode.longBreak:
        minutes = _longBreakDurationMinutes;
        break;
    }
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  /// BẮT ĐẦU ĐẾM NGƯỢC (Start)
  void startTimer() {
    if (_isRunning && !_isPaused) return;

    _isRunning = true;
    _isPaused = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds == 0) {
          unawaited(_handleTimerCompleted());
          return;
        }
        // Đổi câu trích dẫn mỗi khi còn chẵn 5 phút để tạo động lực mới
        if (_remainingSeconds % 300 == 0) {
          _quoteIndex++;
        }
        notifyListeners();
      } else {
        // HẾT GIỜ (00:00) -> KÍCH HOẠT NGHIỆM THU!
        _handleTimerCompleted();
      }
    });

    notifyListeners();
  }

  /// TẠM DỪNG (Pause)
  void pauseTimer() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  /// TIẾP TỤC (Resume)
  void resumeTimer() {
    if (!_isRunning || !_isPaused) return;
    startTimer();
  }

  /// ĐẶT LẠI (Reset)
  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _resetTimeToCurrentMode();
    notifyListeners();
  }

  /// BỎ QUA PHIÊN HIỆN TẠI VÀ CHUYỂN PHIÊN
  void skipSession() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _autoSwitchToNextMode();
    notifyListeners();
  }

  /// CHUYỂN ĐỔI CHẾ ĐỘ THỦ CÔNG
  void switchMode(PomodoroMode mode) {
    if (_currentMode == mode) return;
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _currentMode = mode;
    _resetTimeToCurrentMode();
    notifyListeners();
  }

  /// TỰ ĐỘNG CHUYỂN CHẾ ĐỘ KHI HẾT PHIÊN
  void _autoSwitchToNextMode() {
    if (_currentMode == PomodoroMode.focus) {
      // Nếu đã đủ chu kỳ (ví dụ 4 phiên) -> Nghỉ dài
      if (_completedSessionsCount % _longBreakInterval == 0) {
        _currentMode = PomodoroMode.longBreak;
      } else {
        _currentMode = PomodoroMode.shortBreak;
      }
    } else {
      // Khi hết giờ nghỉ -> Quay lại tập trung
      _currentMode = PomodoroMode.focus;
    }
    _resetTimeToCurrentMode();
  }

  /// XỬ LÝ KHI ĐỒNG HỒ VỀ 00:00 (TIÊU CHÍ NGHIỆM THU!)
  /// 1. Phát âm thanh chuông báo và rung haptic
  /// 2. Tự động lưu phiên học vào SQLite
  /// 3. Đồng bộ với DisciplineProvider để tăng Streak & cập nhật Heatmap
  Future<void> _handleTimerCompleted() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    // 1. Phát âm thanh chuông báo và rung phản hồi
    if (_isSoundEnabled) {
      await _alarmPlayer.play();
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {
        debugPrint('Pomodoro haptic feedback failed: $e');
      }
    }

    final completedMode = _currentMode;
    final durationMinutes = completedMode == PomodoroMode.focus
        ? _focusDurationMinutes
        : (completedMode == PomodoroMode.shortBreak
            ? _shortBreakDurationMinutes
            : _longBreakDurationMinutes);

    // 2. Tự động lưu phiên học vào cơ sở dữ liệu SQLite
    await PomodoroDatabaseHelper.instance.insertSession(
      PomodoroRecord(
        mode: completedMode.name,
        durationMinutes: durationMinutes,
        completedAt: DateTime.now(),
        quote: currentQuote,
        isCompleted: true,
      ),
    );

    // 3. Nếu là phiên tập trung -> Cập nhật thống kê và tự động đồng bộ DisciplineProvider
    if (completedMode == PomodoroMode.focus) {
      _completedSessionsCount++;
      _totalFocusMinutesToday += durationMinutes;

      // Kích hoạt cập nhật thời gian thực trên Dashboard (Streak 🔥, Vòng tròn mục tiêu, Heatmap)
      _disciplineProvider?.completeStudySession(
        minutes: durationMinutes,
        subject: 'Đồng Hồ Focus Pomodoro',
        note: 'Hoàn thành phiên tập trung sâu $durationMinutes phút',
      );
    }

    // Đổi sang phiên tiếp theo
    _autoSwitchToNextMode();
    notifyListeners();
  }

  /// BẬT / TẮT CHẾ ĐỘ KHÓA XAO NHÃNG (Distraction Lock Mode)
  void toggleDistractionLock() {
    _isDistractionLockEnabled = !_isDistractionLockEnabled;
    notifyListeners();
  }

  /// BẬT / TẮT ÂM THANH CHUÔNG BÁO
  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
  }

  /// ĐỔI CÂU TRÍCH DẪN KHUYẾN KHÍCH
  void nextQuote() {
    _quoteIndex++;
    notifyListeners();
  }

  /// CẬP NHẬT CẤU HÌNH THỜI GIAN TRONG SETTINGS
  void updateSettings({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
    bool? soundEnabled,
    bool? distractionLock,
  }) {
    if (focusMinutes != null && focusMinutes > 0) {
      _focusDurationMinutes = focusMinutes;
    }
    if (shortBreakMinutes != null && shortBreakMinutes > 0) {
      _shortBreakDurationMinutes = shortBreakMinutes;
    }
    if (longBreakMinutes != null && longBreakMinutes > 0) {
      _longBreakDurationMinutes = longBreakMinutes;
    }
    if (longBreakInterval != null && longBreakInterval > 0) {
      _longBreakInterval = longBreakInterval;
    }
    if (soundEnabled != null) {
      _isSoundEnabled = soundEnabled;
    }
    if (distractionLock != null) {
      _isDistractionLockEnabled = distractionLock;
    }

    // Nếu đồng hồ đang dừng, cập nhật lại thời gian theo cài đặt mới
    if (!_isRunning) {
      _resetTimeToCurrentMode();
    }

    notifyListeners();
  }

  /// Hàm giả lập nhanh 10 giây cuối dành riêng cho việc test và quay video nghiệm thu
  void setRemainingSecondsForTesting(int seconds) {
    _remainingSeconds = seconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_alarmPlayer.dispose());
    super.dispose();
  }
}
