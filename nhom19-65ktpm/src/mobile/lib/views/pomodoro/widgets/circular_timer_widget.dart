import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pomodoro_provider.dart';

/// Widget Vòng tròn đếm ngược hoạt họa (Animated Circular Timer)
/// Hiển thị phút/giây kỹ thuật số và thanh tiến độ bo tròn chuẩn Material 3
class CircularTimerWidget extends StatelessWidget {
  const CircularTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pomodoro = Provider.of<PomodoroProvider>(context);

    // Xác định màu sắc theo chế độ hiện tại
    Color modeColor;
    Color gradientEndColor;
    IconData modeIcon;

    switch (pomodoro.currentMode) {
      case PomodoroMode.focus:
        modeColor = const Color(0xFFEA580C); // Cam lửa
        gradientEndColor = const Color(0xFFEF4444); // Đỏ nhiệt huyết
        modeIcon = Icons.local_fire_department_rounded;
        break;
      case PomodoroMode.shortBreak:
        modeColor = const Color(0xFF10B981); // Xanh ngọc Emerald
        gradientEndColor = const Color(0xFF059669);
        modeIcon = Icons.coffee_rounded;
        break;
      case PomodoroMode.longBreak:
        modeColor = const Color(0xFF3B82F6); // Xanh dương tĩnh lặng
        gradientEndColor = const Color(0xFF2563EB);
        modeIcon = Icons.spa_rounded;
        break;
    }

    final progress = pomodoro.progressRate;
    final isRunning = pomodoro.isRunning && !pomodoro.isPaused;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vòng phát sáng phía sau khi đồng hồ đang chạy
          if (isRunning)
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: modeColor.withOpacity(isDark ? 0.35 : 0.22),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),

          // Vòng nền (Track circle)
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withOpacity(0.6)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // Vòng tiến độ bo tròn StrokeCap.round
          SizedBox(
            width: 240,
            height: 240,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              builder: (context, animatedValue, child) {
                return CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark
                      ? const Color(0xFF334155).withOpacity(0.4)
                      : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                );
              },
            ),
          ),

          // Nội dung trung tâm: Icon, Thời gian số, Trạng thái
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Huy hiệu chế độ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, size: 16, color: modeColor),
                    const SizedBox(width: 6),
                    Text(
                      pomodoro.modeTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: modeColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hiển thị thời gian kỹ thuật số (mm:ss)
              Text(
                pomodoro.formattedTime,
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Trạng thái phiên đếm ngược
              Text(
                pomodoro.isRunning
                    ? (pomodoro.isPaused
                        ? 'Đang tạm dừng ⏸️'
                        : 'Đang tập trung cao độ 🎯')
                    : 'Sẵn sàng bắt đầu ✨',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
