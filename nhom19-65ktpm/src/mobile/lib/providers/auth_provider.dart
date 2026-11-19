import 'package:flutter/foundation.dart';

/// Lớp đại diện cho thông tin người dùng cơ bản
class AppUser {
  final String id;
  final String fullName;
  final String email;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
  });
}

/// Provider quản lý logic xác thực người dùng (Đăng nhập, Đăng ký, Đăng xuất)
/// Tích hợp các hàm kiểm tra hợp lệ dữ liệu (Validation) chuẩn xác
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Regex kiểm tra định dạng email chuẩn quốc tế
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Kiểm tra tính hợp lệ của Họ và Tên
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Kiểm tra tính hợp lệ của Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Email không đúng định dạng (VD: example@domain.com)';
    }
    return null;
  }

  /// Kiểm tra tính hợp lệ của Mật khẩu (tối thiểu 6 ký tự)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra xác nhận mật khẩu có trùng khớp không
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Giả lập quá trình Đăng nhập
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(milliseconds: 1000));

    final emailError = validateEmail(email);
    final passError = validatePassword(password);

    if (emailError != null || passError != null) {
      _errorMessage = emailError ?? passError;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Đăng nhập thành công
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: email.split('@').first,
      email: email,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Giả lập quá trình Đăng ký
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(milliseconds: 1200));

    final nameError = validateFullName(fullName);
    final emailError = validateEmail(email);
    final passError = validatePassword(password);

    if (nameError != null || emailError != null || passError != null) {
      _errorMessage = nameError ?? emailError ?? passError;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Đăng ký thành công và tự động đăng nhập
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Đăng xuất khỏi hệ thống
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
