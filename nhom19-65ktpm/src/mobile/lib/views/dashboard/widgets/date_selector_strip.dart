import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/discipline_provider.dart';

/// Widget Dải chọn ngày cuộn ngang (DateSelectorStrip)
/// Cho phép người dùng duyệt và xem lại lịch sử học tập các ngày trong tuần
/// Thiết kế chuẩn Material 3 với hoạt họa chọn ngày phản hồi nhanh
class DateSelectorStrip extends StatelessWidget {
  const DateSelectorStrip({super.key});

  static const List<String> _weekdayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final discipline = Provider.of<DisciplineProvider>(context);

    final selectedDate = discipline.selectedDate;
    final weekDates = discipline.getWeekDatesForSelectedDate();
    final now = DateTime.now();
    final isTodaySelected = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          // Header: Tháng/Năm và nút nhảy về Hôm nay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tháng ${selectedDate.month}, ${selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (!isTodaySelected)
                InkWell(
                  onTap: () => discipline.goToToday(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hôm nay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Dải 7 ngày trong tuần dạng cuộn ngang (Horizontal Day Strip)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(weekDates.length, (index) {
                final date = weekDates[index];
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                final dayMinutes = discipline.getMinutesForDate(date);
                final isCompleted = dayMinutes >= discipline.dailyGoalMinutes;
                final hasLearned = dayMinutes > 0;

                final weekdayLabel = _weekdayLabels[date.weekday - 1];

                return GestureDetector(
                  onTap: () => discipline.setSelectedDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : (isToday
                              ? (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFEEF2FF))
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : (isToday
                                ? colorScheme.primary.withOpacity(0.4)
                                : (isDark
                                    ? const Color(0xFF334155).withOpacity(0.6)
                                    : const Color(0xFFE2E8F0))),
                        width: isSelected || isToday ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tên thứ (T2, T3... CN)
                        Text(
                          weekdayLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Số ngày trong tháng
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Chấm trạng thái hoàn thành học tập
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : (isCompleted
                                    ? const Color(0xFF10B981)
                                    : (hasLearned
                                        ? const Color(0xFFF59E0B)
                                        : (isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1)))),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Tóm tắt ngày đang chọn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.6)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTodaySelected
                      ? 'Hôm nay: ${discipline.todayMinutesLearned} phút học'
                      : 'Ngày ${selectedDate.day}/${selectedDate.month}: ${discipline.getMinutesForDate(selectedDate)} phút học',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
                Text(
                  discipline.getMinutesForDate(selectedDate) >=
                          discipline.dailyGoalMinutes
                      ? 'Đạt mục tiêu ✓'
                      : 'Chưa đạt mục tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: discipline.getMinutesForDate(selectedDate) >=
                            discipline.dailyGoalMinutes
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
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
