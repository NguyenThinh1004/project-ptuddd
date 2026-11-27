import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/discipline_provider.dart';

/// Widget Bản đồ nhiệt độ học tập 30 ngày (Monthly Heatmap Grid)
/// Thiết kế chuẩn phong cách GitHub Contribution với sắc xanh lá đậm dần theo mức độ học
/// Hỗ trợ tương tác chạm xem chi tiết từng ngày và tự động cập nhật thời gian thực
class MonthlyHeatmapGrid extends StatelessWidget {
  const MonthlyHeatmapGrid({super.key});

  /// Bảng màu GitHub Contribution theo mức độ rèn luyện (Level 0 - 4)
  static Color getCellColor(int level, bool isDark) {
    if (isDark) {
      switch (level) {
        case 1:
          return const Color(0xFF0E4429); // Xanh nhạt Dark
        case 2:
          return const Color(0xFF006D32); // Xanh vừa Dark
        case 3:
          return const Color(0xFF26A641); // Xanh đậm Dark
        case 4:
          return const Color(0xFF39D353); // Xanh sáng Dark
        default:
          return const Color(0xFF1E293B); // Không có đóng góp
      }
    } else {
      switch (level) {
        case 1:
          return const Color(0xFF9BE9A8); // Level 1 Light
        case 2:
          return const Color(0xFF40C463); // Level 2 Light
        case 3:
          return const Color(0xFF30A14E); // Level 3 Light
        case 4:
          return const Color(0xFF216E39); // Level 4 Light
        default:
          return const Color(0xFFEBEDF0); // Không có đóng góp
      }
    }
  }

  void _showDayDetailDialog(
    BuildContext context,
    DayStudyRecord record,
    bool isDark,
  ) {
    final dayStr =
        '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}';
    final weekdayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final weekdayStr = weekdayNames[record.date.weekday - 1];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$weekdayStr, $dayStr',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhật ký rèn luyện cá nhân',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: getCellColor(record.level, isDark),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Thời gian học',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${record.minutes} phút',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          const Text('Mức độ',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'Level ${record.level}/4',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          const Text('Trạng thái',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            record.isCompleted ? 'Đạt chỉ tiêu' : 'Chưa đạt',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: record.isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final discipline = Provider.of<DisciplineProvider>(context);

    // Lấy 30 bản ghi ngày gần nhất
    final records = discipline.getMonthlyHeatmapRecords(30);
    final now = DateTime.now();

    // Tính tổng số phút học trong 30 ngày qua
    final totalMinutes30Days =
        records.fold<int>(0, (sum, record) => sum + record.minutes);
    final activeDaysCount =
        records.where((record) => record.minutes > 0).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề và tổng quan 30 ngày
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản đồ nhiệt độ học tập (30 ngày)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Phong cách GitHub Contribution',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeDaysCount/30 ngày',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Lưới ô vuông 30 ngày (Monthly Heatmap Grid)
          // 5 hàng x 6 cột hoặc 6 cột x 5 hàng (tổng 30 ô)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // 6 cột x 5 hàng = 30 ngày
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final record = records[index];
              final isToday = record.date.year == now.year &&
                  record.date.month == now.month &&
                  record.date.day == now.day;
              final cellColor = getCellColor(record.level, isDark);

              return Tooltip(
                message:
                    '${record.date.day}/${record.date.month}: ${record.minutes} phút học',
                child: InkWell(
                  onTap: () => _showDayDetailDialog(context, record, isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 2.2,
                            )
                          : Border.all(
                              color: isDark
                                  ? const Color(0xFF334155).withOpacity(0.4)
                                  : Colors.black.withOpacity(0.04),
                              width: 1,
                            ),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFF59E0B).withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${record.date.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: record.level >= 2
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155)),
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Footer của Heatmap: Thống kê tổng giờ & Thang đo màu (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng: ${(totalMinutes30Days / 60).toStringAsFixed(1)} giờ học',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),

              // Thang đo màu (Contribution Legend)
              Row(
                children: [
                  Text(
                    'Ít',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (int lvl = 0; lvl <= 4; lvl++)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: getCellColor(lvl, isDark),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.black.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    'Nhiều',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
