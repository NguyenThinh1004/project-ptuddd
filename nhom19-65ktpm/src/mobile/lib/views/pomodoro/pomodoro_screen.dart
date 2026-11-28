import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/discipline_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../services/pomodoro_database_helper.dart';
import '../auth/theme_toggle_button.dart';
import 'widgets/circular_timer_widget.dart';
import 'widgets/distraction_lock_view.dart';
import 'widgets/pomodoro_settings_sheet.dart';
import 'widgets/timer_controls.dart';

/// Màn hình Đồng hồ bấm giờ tập trung Focus Pomodoro
/// Giúp người học tập trung sâu theo chu kỳ 25 phút học + 5 phút nghỉ
/// Tích hợp khóa xao nhãng, chuông báo và lưu cơ sở dữ liệu SQLite
class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  void _openSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PomodoroSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final discipline = Provider.of<DisciplineProvider>(context);

    // Đảm bảo PomodoroProvider liên kết với DisciplineProvider
    pomodoro.updateDisciplineProvider(discipline);

    // Nếu đang bật Chế độ Khóa xao nhãng -> Hiển thị toàn màn hình tối giản
    if (pomodoro.isDistractionLockEnabled) {
      return DistractionLockView(
        onUnlock: () {
          pomodoro.toggleDistractionLock();
        },
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Đồng Hồ Focus Pomodoro',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tùy chỉnh thời gian',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openSettingsSheet(context),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Thanh chọn 3 chế độ: Tập trung (25p) - Nghỉ ngắn (5p) - Nghỉ dài (15p)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildModeTab(
                      context,
                      title: 'Tập trung (${pomodoro.focusDurationMinutes}p)',
                      mode: PomodoroMode.focus,
                      activeColor: const Color(0xFFEA580C),
                      isSelected: pomodoro.currentMode == PomodoroMode.focus,
                    ),
                    _buildModeTab(
                      context,
                      title:
                          'Nghỉ ngắn (${pomodoro.shortBreakDurationMinutes}p)',
                      mode: PomodoroMode.shortBreak,
                      activeColor: const Color(0xFF10B981),
                      isSelected:
                          pomodoro.currentMode == PomodoroMode.shortBreak,
                    ),
                    _buildModeTab(
                      context,
                      title: 'Nghỉ dài (${pomodoro.longBreakDurationMinutes}p)',
                      mode: PomodoroMode.longBreak,
                      activeColor: const Color(0xFF3B82F6),
                      isSelected:
                          pomodoro.currentMode == PomodoroMode.longBreak,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Checklist 1: Vòng tròn đếm ngược hoạt họa (Animated Circular Timer)
              const CircularTimerWidget(),
              const SizedBox(height: 32),

              // Checklist 2: Các nút điều khiển Start, Pause, Reset
              TimerControls(
                onOpenSettings: () => _openSettingsSheet(context),
              ),
              const SizedBox(height: 28),

              // Checklist 4: Câu trích dẫn truyền cảm hứng học tập
              GestureDetector(
                onTap: () => pomodoro.nextQuote(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: Color(0xFFF59E0B),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pomodoro.currentQuote,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Thẻ thống kê phiên tập trung hôm nay & Cơ sở dữ liệu SQLite
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storage_rounded,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nhật Ký Phiên Học ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tự động lưu ✓',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            title: 'Phiên hôm nay',
                            value: '${pomodoro.completedSessionsCount} phiên',
                            color: const Color(0xFFEA580C),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            title: 'Thời gian tập trung',
                            value: '${pomodoro.totalFocusMinutesToday} phút',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context, {
    required String title,
    required PomodoroMode mode,
    required Color activeColor,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);

    return Expanded(
      child: GestureDetector(
        onTap: () => pomodoro.switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
