import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pomodoro_provider.dart';

/// Widget cụm các nút điều khiển: Bắt đầu (Start), Tạm dừng (Pause), Đặt lại (Reset)
/// Chuẩn Material 3 với nút trung tâm nổi bật và phản hồi chạm nhạy
class TimerControls extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const TimerControls({
    super.key,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pomodoro = Provider.of<PomodoroProvider>(context);

    // Màu sắc theo chế độ hiện tại
    Color activeColor;
    switch (pomodoro.currentMode) {
      case PomodoroMode.focus:
        activeColor = const Color(0xFFEA580C);
        break;
      case PomodoroMode.shortBreak:
        activeColor = const Color(0xFF10B981);
        break;
      case PomodoroMode.longBreak:
        activeColor = const Color(0xFF3B82F6);
        break;
    }

    final isRunning = pomodoro.isRunning;
    final isPaused = pomodoro.isPaused;

    return Column(
      children: [
        // Hàng điều khiển chính: [Reset] - [START/PAUSE] - [Skip]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nút Đặt lại (Reset)
            IconButton.filledTonal(
              iconSize: 26,
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                padding: const EdgeInsets.all(16),
              ),
              tooltip: 'Đặt lại đồng hồ',
              onPressed: () => pomodoro.resetTimer(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 24),

            // Nút Chính: Bắt đầu (Start) / Tạm dừng (Pause)
            GestureDetector(
              onTap: () {
                if (!isRunning) {
                  pomodoro.startTimer();
                } else if (isPaused) {
                  pomodoro.resumeTimer();
                } else {
                  pomodoro.pauseTimer();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      activeColor,
                      activeColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    (!isRunning || isPaused)
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Nút Chuyển phiên tiếp theo (Skip)
            IconButton.filledTonal(
              iconSize: 26,
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                padding: const EdgeInsets.all(16),
              ),
              tooltip: 'Bỏ qua & Chuyển phiên tiếp theo',
              onPressed: () => pomodoro.skipSession(),
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Hàng điều khiển phụ: Bật Khóa xao nhãng & Mở Cài đặt thời gian
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nút Khóa xao nhãng (Distraction Lock)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: pomodoro.isDistractionLockEnabled
                      ? const Color(0xFF10B981)
                      : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569)),
                  side: BorderSide(
                    color: pomodoro.isDistractionLockEnabled
                        ? const Color(0xFF10B981)
                        : (isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1)),
                  ),
                  minimumSize: const Size(0, 52),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  pomodoro.isDistractionLockEnabled
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 18,
                ),
                label: Text(
                  pomodoro.isDistractionLockEnabled
                      ? 'Đang Khóa Xao Nhãng'
                      : 'Bật Khóa Xao Nhãng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                onPressed: () {
                  pomodoro.toggleDistractionLock();
                },
              ),
            ),
            const SizedBox(width: 12),

            // Nút Cài đặt (Settings)
            IconButton.outlined(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              tooltip: 'Tùy chỉnh thời gian & âm thanh',
              icon: const Icon(Icons.tune_rounded, size: 20),
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ],
    );
  }
}
