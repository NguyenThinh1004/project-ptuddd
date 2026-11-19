import 'package:flutter/material.dart';

/// Quản lý trạng thái Theme (Light/Dark mode) cho toàn bộ ứng dụng
/// Hỗ trợ chuyển đổi mượt mà và thông báo cập nhật giao diện ngay lập tức
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Chuyển đổi qua lại giữa Light và Dark Theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Đặt trực tiếp chế độ ThemeMode mong muốn
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}
