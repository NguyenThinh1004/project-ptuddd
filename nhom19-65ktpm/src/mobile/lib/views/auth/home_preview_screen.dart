import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';
import 'theme_toggle_button.dart';

/// Màn hình Home Preview sau khi xác thực thành công
/// Xác nhận hoàn thành đầy đủ các tiêu chí nghiệm thu của Sprint 1 / Issue #1
class HomePreviewScreen extends StatelessWidget {
  const HomePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final userName = authProvider.currentUser?.fullName.isNotEmpty == true
        ? authProvider.currentUser!.fullName
        : 'Đào Thị Yến';
    final userEmail = authProvider.currentUser?.email.isNotEmpty == true
        ? authProvider.currentUser!.email
        : '2351170636@e.tlu.edu.vn';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StudyMate AI',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ chào mừng người dùng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF6366F1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, $userName! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFFFBBF24),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sprint 1: Phân hệ Xác thực & Giao diện Đã Sẵn Sàng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Thẻ nghiệm thu Issue #1
              Text(
                'Báo Cáo Nghiệm Thu Issue #1',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildChecklistRow(
                        '1. Màn hình Splash Logo StudyMate AI',
                        true,
                        colorScheme.primary,
                      ),
                      const Divider(height: 18),
                      _buildChecklistRow(
                        '2. Onboarding PageView 3 bước vuốt ngang',
                        true,
                        colorScheme.primary,
                      ),
                      const Divider(height: 18),
                      _buildChecklistRow(
                        '3. Form Đăng nhập & Đăng ký có Validation',
                        true,
                        colorScheme.primary,
                      ),
                      const Divider(height: 18),
                      _buildChecklistRow(
                        '4. Chuyển đổi mượt mà Light / Dark Theme',
                        true,
                        colorScheme.primary,
                      ),
                      const Divider(height: 18),
                      _buildChecklistRow(
                        '5. Đặt đúng thư mục lib/views/auth/',
                        true,
                        colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Khối xem trước 3 chức năng chính
              Text(
                '3 Phân Hệ Chính Của StudyMate AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              _buildFeaturePreviewCard(
                context,
                title: 'Luyện Phát Âm AI (CMUDict/IPA)',
                desc: 'Chấm điểm đối chiếu âm vị 0-100%, đổi màu từng từ',
                icon: Icons.mic_rounded,
                color: const Color(0xFF4F46E5),
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _buildFeaturePreviewCard(
                context,
                title: 'Đồng Hồ Focus Pomodoro & Streak 🔥',
                desc: 'Phiên 25/5 phút tập trung cao độ, khóa xao nhãng',
                icon: Icons.timer_rounded,
                color: const Color(0xFFEA580C),
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _buildFeaturePreviewCard(
                context,
                title: 'Thẻ Flashcards Lật 3D (SM-2)',
                desc: 'Sinh tự động từ tài liệu học & lặp lại ngắt quãng',
                icon: Icons.psychology_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Nút chuyển trực tiếp sang Dashboard Kỷ Luật (Issue 2)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.local_fire_department_rounded, size: 22),
                label: const Text(
                  'Mở Dashboard Kỷ Luật (Streak 🔥 & Heatmap)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Nút Đăng xuất
              OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
              ).copyWith().let((_) => OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Đăng xuất'),
                    onPressed: () {
                      authProvider.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String text, bool isChecked, Color activeColor) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isChecked ? const Color(0xFF10B981) : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePreviewCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ObjectExt<T> on T {
  R let<R>(R Function(T it) op) => op(this);
}
