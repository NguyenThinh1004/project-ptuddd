import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pomodoro_provider.dart';

/// BottomSheet tùy chỉnh thời gian linh hoạt trong Settings
/// 25 phút tập trung, 5 phút nghỉ ngắn, 15 phút nghỉ dài, âm thanh và khóa xao nhãng
class PomodoroSettingsSheet extends StatefulWidget {
  const PomodoroSettingsSheet({super.key});

  @override
  State<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<PomodoroSettingsSheet> {
  late double _focusMinutes;
  late double _shortBreakMinutes;
  late double _longBreakMinutes;
  late bool _soundEnabled;
  late bool _distractionLock;

  @override
  void initState() {
    super.initState();
    final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);
    _focusMinutes = pomodoro.focusDurationMinutes.toDouble();
    _shortBreakMinutes = pomodoro.shortBreakDurationMinutes.toDouble();
    _longBreakMinutes = pomodoro.longBreakDurationMinutes.toDouble();
    _soundEnabled = pomodoro.isSoundEnabled;
    _distractionLock = pomodoro.isDistractionLockEnabled;
  }

  void _saveSettings() {
    final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);
    pomodoro.updateSettings(
      focusMinutes: _focusMinutes.round(),
      shortBreakMinutes: _shortBreakMinutes.round(),
      longBreakMinutes: _longBreakMinutes.round(),
      soundEnabled: _soundEnabled,
      distractionLock: _distractionLock,
    );
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cấu hình thời gian Pomodoro thành công!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setQuickTestCountdown() {
    final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);
    // Đặt đồng hồ về 10 giây cuối và bắt đầu chạy để kiểm thử nghiệm thu
    pomodoro.setRemainingSecondsForTesting(10);
    pomodoro.startTimer();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang chạy thử 10 giây cuối để kiểm tra chuông báo & lưu SQLite!'),
        backgroundColor: Color(0xFFEA580C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạt trên đỉnh Sheet
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề cài đặt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFFEA580C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tùy Chỉnh Pomodoro',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _focusMinutes = 25;
                      _shortBreakMinutes = 5;
                      _longBreakMinutes = 15;
                    });
                  },
                  child: const Text('Mặc định (25/5/15)'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Thời gian tập trung (Focus)
            _buildSliderItem(
              title: 'Thời gian tập trung',
              value: _focusMinutes,
              min: 5,
              max: 60,
              unit: 'phút',
              color: const Color(0xFFEA580C),
              onChanged: (val) => setState(() => _focusMinutes = val),
            ),
            const SizedBox(height: 18),

            // 2. Thời gian nghỉ ngắn (Short Break)
            _buildSliderItem(
              title: 'Thời gian nghỉ ngắn',
              value: _shortBreakMinutes,
              min: 1,
              max: 15,
              unit: 'phút',
              color: const Color(0xFF10B981),
              onChanged: (val) => setState(() => _shortBreakMinutes = val),
            ),
            const SizedBox(height: 18),

            // 3. Thời gian nghỉ dài (Long Break)
            _buildSliderItem(
              title: 'Thời gian nghỉ dài',
              value: _longBreakMinutes,
              min: 5,
              max: 30,
              unit: 'phút',
              color: const Color(0xFF3B82F6),
              onChanged: (val) => setState(() => _longBreakMinutes = val),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 8),

            // Tùy chọn Bật/Tắt Âm thanh chuông báo
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Âm thanh chuông báo khi về 00:00',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Phát âm thanh chuông và rung phản hồi khi kết thúc phiên',
                style: TextStyle(fontSize: 12),
              ),
              activeColor: const Color(0xFFEA580C),
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),

            // Tùy chọn Giữ màn hình luôn sáng (Wakelock)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Chế độ khóa xao nhãng (Wakelock)',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Giữ màn hình luôn sáng và hiển thị trích dẫn truyền cảm hứng',
                style: TextStyle(fontSize: 12),
              ),
              activeColor: const Color(0xFF10B981),
              value: _distractionLock,
              onChanged: (val) => setState(() => _distractionLock = val),
            ),
            const SizedBox(height: 20),

            // Nút thử nghiệm nhanh dành cho kiểm thử nghiệm thu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEA580C).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, color: Color(0xFFEA580C), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Kiểm thử nhanh: Đếm 10 giây để nghe chuông & kiểm tra lưu SQLite',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _setQuickTestCountdown,
                    child: const Text('Thử ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nút Lưu cài đặt
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saveSettings,
              child: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} $unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
