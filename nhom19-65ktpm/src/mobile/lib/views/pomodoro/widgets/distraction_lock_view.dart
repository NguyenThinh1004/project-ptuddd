import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pomodoro_provider.dart';

/// Chế độ khóa xao nhãng toàn màn hình (Distraction Lock Mode)
/// Giữ màn hình luôn sáng (Wakelock) và hiển thị câu trích dẫn truyền cảm hứng học tập
class DistractionLockView extends StatelessWidget {
  final VoidCallback onUnlock;

  const DistractionLockView({
    super.key,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final isRunning = pomodoro.isRunning && !pomodoro.isPaused;

    Color accentColor;
    switch (pomodoro.currentMode) {
      case PomodoroMode.focus:
        accentColor = const Color(0xFFEA580C);
        break;
      case PomodoroMode.shortBreak:
        accentColor = const Color(0xFF10B981);
        break;
      case PomodoroMode.longBreak:
        accentColor = const Color(0xFF3B82F6);
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Nền tối sâu loại bỏ mọi phân tâm
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Thanh thông báo trên cùng: Trạng thái Khóa xao nhãng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'Khóa Xao Nhãng Đang Bật',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút mở khóa (Unlock button)
                  IconButton(
                    tooltip: 'Thoát chế độ khóa xao nhãng',
                    icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70),
                    onPressed: () {
                      _showUnlockConfirmDialog(context);
                    },
                  ),
                ],
              ),

              // Trung tâm: Đồng hồ số siêu tối giản và vòng tròn phát sáng
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Huy hiệu chế độ
                  Text(
                    pomodoro.modeTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thời gian đếm ngược lớn
                  Text(
                    pomodoro.formattedTime,
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thanh tiến độ mỏng thanh lịch
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pomodoro.progressRate,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nút tạm dừng / tiếp tục tối giản
                  IconButton.filledTonal(
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                    ),
                    onPressed: () {
                      if (!isRunning) {
                        pomodoro.startTimer();
                      } else {
                        pomodoro.pauseTimer();
                      }
                    },
                    icon: Icon(
                      isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),

              // Dưới cùng: Thẻ trích dẫn truyền cảm hứng học tập (Inspirational Quote)
              GestureDetector(
                onTap: () => pomodoro.nextQuote(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: Color(0xFFFBBF24),
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pomodoro.currentQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chạm để đổi câu trích dẫn ✨',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Thoát chế độ tập trung?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn đang trong phiên rèn luyện kỷ luật. Bạn có chắc muốn tắt màn hình khóa xao nhãng?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tiếp tục tập trung', style: TextStyle(color: Color(0xFF10B981))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onUnlock();
            },
            child: const Text('Tắt khóa'),
          ),
        ],
      ),
    );
  }
}
