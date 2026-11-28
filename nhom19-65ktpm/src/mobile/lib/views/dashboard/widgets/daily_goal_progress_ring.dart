import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/discipline_provider.dart';

/// Widget Vòng tròn tiến độ mục tiêu ngày (Daily Goal Progress Ring)
/// Trực quan hóa số phút học hôm nay (ví dụ: hoàn thành 25/30 phút học)
/// Cập nhật hoạt họa mượt mà khi người dùng hoàn thành phiên học
class DailyGoalProgressRing extends StatelessWidget {
  const DailyGoalProgressRing({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final discipline = Provider.of<DisciplineProvider>(context);

    final todayMinutes = discipline.todayMinutesLearned;
    final goalMinutes = discipline.dailyGoalMinutes;
    final progressRate = discipline.todayProgressRate;
    final percent = discipline.todayProgressPercent;
    final isCompleted = discipline.isTodayGoalCompleted;

    // Màu sắc tiến độ: Nếu đã hoàn thành chuyển sang xanh lục (Emerald),
    // nếu chưa thì chuyển từ Indigo sang Orange
    final progressColor = isCompleted
        ? const Color(0xFF10B981)
        : (progressRate >= 0.75
            ? const Color(0xFF4F46E5)
            : const Color(0xFF6366F1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tiêu đề phân hệ mục tiêu ngày
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mục tiêu học hôm nay',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Hoàn thành 🎉' : '$todayMinutes / $goalMinutes phút',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF4F46E5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vòng tròn tiến độ (Daily Goal Progress Ring) có Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progressRate),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng tròn ngoài phát sáng nhẹ khi đạt mục tiêu
                  if (isCompleted)
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),

                  // Vòng tròn tiến độ Custom vẽ tròn với nét bo góc Material 3
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFEEF2F6),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),

                  // Nội dung trung tâm vòng tròn: Phần trăm & Số phút học
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$percent',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$todayMinutes / $goalMinutes phút',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),

          // Trạng thái khích lệ & chi tiết
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.verified_rounded
                      : Icons.lightbulb_outline_rounded,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isCompleted
                        ? 'Xuất sắc! Bạn đã vượt chỉ tiêu học tập hôm nay!'
                        : 'Chỉ còn ${discipline.remainingMinutesToday} phút để thắp sáng mục tiêu!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
