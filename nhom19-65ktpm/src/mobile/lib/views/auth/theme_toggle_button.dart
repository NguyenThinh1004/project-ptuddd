import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// Nút bấm chuyển đổi nhanh chế độ Sáng / Tối (Light / Dark Theme)
/// Thiết kế thanh lịch chuẩn Material 3, có hiệu ứng hoạt họa mượt mà
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      tooltip: isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: child.key == const ValueKey('dark')
              ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
              : Tween<double>(begin: 0.25, end: 1.0).animate(anim),
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: isDark
            ? const Icon(
                Icons.light_mode_rounded,
                key: ValueKey('dark'),
                color: Color(0xFFFBBF24), // Vàng nắng
                size: 24,
              )
            : const Icon(
                Icons.dark_mode_rounded,
                key: ValueKey('light'),
                color: Color(0xFF475569), // Slate tối
                size: 24,
              ),
      ),
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}
