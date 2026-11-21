import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'theme_toggle_button.dart';

/// Dữ liệu đại diện cho từng bước giới thiệu trong Onboarding
class OnboardingStepItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> tags;
  final Color accentColor;

  const OnboardingStepItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.tags,
    required this.accentColor,
  });
}

/// Màn hình Onboarding giới thiệu 3 tính năng cốt lõi của StudyMate AI
/// 1. Luyện phát âm AI (Speech Assessment)
/// 2. Đồng hồ Pomodoro & Kỷ luật (Streak)
/// 3. Thẻ Flashcards Spaced Repetition (SM-2)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Danh sách 3 bước vuốt ngang theo đúng yêu cầu đề bài
  final List<OnboardingStepItem> _steps = const [
    OnboardingStepItem(
      title: 'Luyện Phát Âm AI',
      subtitle: 'Đối chiếu âm vị chuẩn quốc tế NLTK CMUDict',
      description:
          'Chấm điểm phát âm từ 0 - 100% theo thời gian thực. Tự động đổi màu trực quan từng từ: Xanh lá (chuẩn), Cam (gần đúng), Đỏ (cần sửa âm).',
      icon: Icons.mic_rounded,
      tags: ['Chấm điểm 0-100%', 'Phân tích âm vị', 'Nghe mẫu bản xứ'],
      accentColor: Color(0xFF4F46E5), // Indigo
    ),
    OnboardingStepItem(
      title: 'Đồng Hồ Pomodoro',
      subtitle: 'Rèn luyện kỷ luật & Khóa xao nhãng',
      description:
          'Phiên học tập 25 phút tập trung + 5 phút nghỉ ngơi khoa học. Xây dựng thói quen tự giác và duy trì ngọn lửa chuỗi ngày học Streak 🔥.',
      icon: Icons.timer_rounded,
      tags: ['Phiên 25/5 chuẩn', 'Khóa xao nhãng', 'Chuỗi ngày Streak 🔥'],
      accentColor: Color(0xFFEA580C), // Orange / Flame
    ),
    OnboardingStepItem(
      title: 'Thẻ Flashcards SM-2',
      subtitle: 'Lặp lại ngắt quãng & Ghi nhớ dài hạn',
      description:
          'Thẻ ghi nhớ lật 3D hai mặt sinh tự động từ tài liệu học bằng AI. Ứng dụng thuật toán Spaced Repetition (SM-2) chống lại đường cong quên lãng.',
      icon: Icons.psychology_rounded,
      tags: ['Thẻ lật 3D', 'Thuật toán SM-2', 'Tự động tạo Quiz'],
      accentColor: Color(0xFF10B981), // Emerald
    ),
  ];

  void _onSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onSkip();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Nút Bỏ qua và Nút đổi Theme
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Bỏ qua (Skip)
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  // Đổi chế độ Light / Dark
                  const ThemeToggleButton(),
                ],
              ),
            ),

            // PageView 3 bước giới thiệu
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildStepPage(context, step, isDark);
                },
              ),
            ),

            // Bottom Navigation Area: Dots Indicator và Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // Dãy chấm chỉ thị vị trí trang (Dots Indicator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _steps[_currentPage].accentColor
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút hành động chính (Tiếp tục hoặc Bắt đầu ngay)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentPage == _steps.length - 1
                        ? ElevatedButton(
                            key: const ValueKey('get_started'),
                            onPressed: _onSkip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _steps[_currentPage].accentColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Bắt đầu ngay'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          )
                        : Row(
                            key: const ValueKey('next_button'),
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _onNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _steps[_currentPage].accentColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Tiếp tục'),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

  /// Xây dựng nội dung từng trang bước giới thiệu (Bọc SingleChildScrollView để chống tràn)
  Widget _buildStepPage(
    BuildContext context,
    OnboardingStepItem step,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Vòng tròn Icon lớn đại diện tính năng với hiệu ứng viền bóng
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.accentColor.withOpacity(isDark ? 0.2 : 0.1),
              border: Border.all(
                color: step.accentColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.accentColor.withOpacity(isDark ? 0.25 : 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                step.icon,
                size: 72,
                color: step.accentColor,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Tiêu đề tính năng
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Phụ đề nổi bật
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: step.accentColor,
            ),
          ),
          const SizedBox(height: 16),

          // Đoạn mô tả chi tiết
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.55,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 24),

          // Các thẻ tính năng nhỏ (Feature chips)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: step.tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
