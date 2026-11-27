import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/discipline_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/theme_toggle_button.dart';
import 'widgets/date_selector_strip.dart';
import 'widgets/daily_goal_progress_ring.dart';
import 'widgets/monthly_heatmap_grid.dart';
import 'widgets/streak_card.dart';

/// Màn hình Trang chủ (Dashboard) trực quan hóa các chỉ số rèn luyện kỷ luật học tập
/// Chuỗi ngày Streak 🔥, Vòng tròn mục tiêu ngày, Bản đồ nhiệt Heatmap 30 ngày
/// Tích hợp phản ứng thời gian thực với DisciplineProvider chuẩn Material 3
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _onCompleteSessionPressed(BuildContext context) {
    final discipline = Provider.of<DisciplineProvider>(context, listen: false);
    final previousStreak = discipline.currentStreak;

    // Kích hoạt hoàn thành 1 phiên học 25 phút
    discipline.completeStudySession(
      minutes: 25,
      subject: 'Đồng Hồ Focus Pomodoro',
      note: 'Hoàn thành phiên tập trung 25 phút',
    );

    final currentStreak = discipline.currentStreak;
    final streakIncreased = currentStreak > previousStreak;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                streakIncreased
                    ? '🎉 Tuyệt vời! Đã hoàn thành 25 phút học & Tăng Streak lên $currentStreak ngày!'
                    : '🎉 Đã ghi nhận +25 phút học tập trung vào mục tiêu hôm nay!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onResetTestPressed(BuildContext context) {
    final discipline = Provider.of<DisciplineProvider>(context, listen: false);
    discipline.resetTodayForTesting();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt lại tiến độ học hôm nay để bạn kiểm thử lại'),
        backgroundColor: Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final discipline = Provider.of<DisciplineProvider>(context);

    final userName = auth.currentUser?.fullName.isNotEmpty == true
        ? auth.currentUser!.fullName
        : 'Đào Thị Yến';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    const Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'daothiyen@e.tlu.edu.vn • Nhóm 19 - 65KTPM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard_rounded, color: colorScheme.primary),
              title: const Text('Dashboard Kỷ Luật Cá Nhân',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              selected: true,
              selectedTileColor: colorScheme.primary.withOpacity(0.1),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: Color(0xFFEA580C)),
              title: const Text('Đồng Hồ Focus Pomodoro ⏱️',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('25p tập trung + 5p nghỉ & Khóa xao nhãng', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/pomodoro');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_rounded, color: Color(0xFF4F46E5)),
              title: const Text('Màn hình Splash Logo'),
              subtitle: const Text('Hiệu ứng chuyển cảnh mượt mà', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/splash');
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_carousel_rounded, color: Color(0xFF10B981)),
              title: const Text('Onboarding Giới Thiệu (3 bước)'),
              subtitle: const Text('AI Speech, Pomodoro, Flashcards', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/onboarding');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFFEA580C)),
              title: const Text('Đăng nhập / Đăng ký'),
              subtitle: const Text('Form xác thực có Validation', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: Color(0xFF6366F1)),
              title: const Text('Báo cáo Nghiệm thu Sprint 1'),
              subtitle: const Text('Tổng quan các tiêu chí đã hoàn thành', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/home');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
              ),
              title: Text(isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối'),
              onTap: () {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    const Color(0xFF8B5CF6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'StudyMate AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Dashboard Kỷ Luật',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh chào mừng người dùng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF6366F1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào bạn, $userName! 👋',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Giữ vững ngọn lửa kỷ luật hôm nay nhé!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Checklist 1: Biểu tượng ngọn lửa chuỗi ngày học liên tục (Streak Flame)
              const StreakCard(),
              const SizedBox(height: 18),

              // Checklist 2: Vòng tròn tiến độ mục tiêu ngày (Daily Goal Progress Ring)
              const DailyGoalProgressRing(),
              const SizedBox(height: 16),

              // Nút hành động nhanh: Hoàn thành 1 phiên học (Kiểm thử Tiêu chí nghiệm thu!)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tương tác kiểm thử Nghiệm thu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => _onCompleteSessionPressed(context),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('Hoàn thành 1 phiên học (+25 phút)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFEA580C)),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/pomodoro'),
                      icon: const Icon(Icons.timer_rounded, size: 20),
                      label: const Text(
                        'Mở Đồng Hồ Focus Pomodoro & Khóa Xao Nhãng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _onResetTestPressed(context),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Đặt lại hôm nay về 0 phút để thử lại'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Checklist 4: Dải chọn ngày cuộn ngang (DateSelectorStrip)
              const DateSelectorStrip(),
              const SizedBox(height: 18),

              // Checklist 3: Bản đồ nhiệt độ học tập 30 ngày (Monthly Heatmap Grid)
              const MonthlyHeatmapGrid(),
              const SizedBox(height: 18),

              // Danh sách phiên học gần đây
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch sử phiên học hôm nay',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${discipline.recentSessions.length} phiên',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (discipline.recentSessions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Chưa có phiên học nào hôm nay. Hãy bắt đầu ngay!',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    else
                      ...discipline.recentSessions.map((session) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withOpacity(0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.subject,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (session.note.isNotEmpty)
                                      Text(
                                        session.note,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${session.minutes} phút',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
}
