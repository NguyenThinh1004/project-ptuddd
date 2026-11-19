import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/views/auth/login_screen.dart';
import 'package:mobile/views/auth/onboarding_screen.dart';
import 'package:mobile/views/auth/register_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('Auth Validation Tests (Tiêu chí nghiệm thu)', () {
    test('Email validation checks format correctly', () {
      // Báo lỗi khi để trống
      expect(AuthProvider.validateEmail(''), isNotNull);
      expect(AuthProvider.validateEmail(null), isNotNull);

      // Báo lỗi khi sai định dạng
      expect(AuthProvider.validateEmail('invalid-email'), isNotNull);
      expect(AuthProvider.validateEmail('user@'), isNotNull);
      expect(AuthProvider.validateEmail('user@domain'), isNotNull);
      expect(AuthProvider.validateEmail('user.domain.com'), isNotNull);

      // Hợp lệ khi đúng định dạng
      expect(AuthProvider.validateEmail('2351170636@e.tlu.edu.vn'), isNull);
      expect(AuthProvider.validateEmail('daothiyen@gmail.com'), isNull);
      expect(AuthProvider.validateEmail('test.ai@studymate.vn'), isNull);
    });

    test('Password validation checks minimum 6 characters', () {
      // Báo lỗi khi để trống
      expect(AuthProvider.validatePassword(''), isNotNull);
      expect(AuthProvider.validatePassword(null), isNotNull);

      // Báo lỗi khi dưới 6 ký tự
      expect(AuthProvider.validatePassword('1'), isNotNull);
      expect(AuthProvider.validatePassword('12345'), isNotNull);
      expect(AuthProvider.validatePassword('abcde'), isNotNull);

      // Hợp lệ khi đủ 6 ký tự trở lên
      expect(AuthProvider.validatePassword('123456'), isNull);
      expect(AuthProvider.validatePassword('password123'), isNull);
      expect(AuthProvider.validatePassword('StudyMate@2026'), isNull);
    });

    test('Full name validation checks length >= 2', () {
      expect(AuthProvider.validateFullName(''), isNotNull);
      expect(AuthProvider.validateFullName(null), isNotNull);
      expect(AuthProvider.validateFullName('A'), isNotNull);

      expect(AuthProvider.validateFullName('Đào Thị Yến'), isNull);
      expect(AuthProvider.validateFullName('Yến'), isNull);
    });

    test('Confirm password checks match', () {
      expect(
        AuthProvider.validateConfirmPassword('123456', '654321'),
        isNotNull,
      );
      expect(
        AuthProvider.validateConfirmPassword('123456', '123456'),
        isNull,
      );
    });
  });

  group('Widget UI & Responsive Tests', () {
    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: child,
            );
          },
        ),
      );
    }

    testWidgets('LoginScreen renders without overflow and validates input',
        (tester) async {
      // Thiết lập kích thước màn hình điện thoại tiêu chuẩn
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Kiểm tra sự xuất hiện của các trường chính
      expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);

      // Nhấn Đăng nhập khi chưa điền dữ liệu -> Kiểm tra báo lỗi Validation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

      // Nhập email sai định dạng và mật khẩu < 6 ký tự
      await tester.enterText(
          find.byType(TextFormField).first, 'email-sai-dinh-dang');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(
        find.text('Email không đúng định dạng (VD: example@domain.com)'),
        findsOneWidget,
      );
      expect(
        find.text('Mật khẩu phải có ít nhất 6 ký tự'),
        findsOneWidget,
      );

      // Khôi phục kích thước test
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('OnboardingScreen displays 3 steps correctly', (tester) async {
      await tester.pumpWidget(createTestApp(const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Bước 1: Luyện phát âm AI
      expect(find.text('Luyện Phát Âm AI'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Nhấn Tiếp tục -> Sang bước 2: Đồng Hồ Pomodoro
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Đồng Hồ Pomodoro'), findsOneWidget);

      // Nhấn Tiếp tục -> Sang bước 3: Thẻ Flashcards SM-2
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Thẻ Flashcards SM-2'), findsOneWidget);
      expect(find.text('Bắt đầu ngay'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders properly with all validation fields',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tạo tài khoản mới 🚀'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Họ tên, Email, Mật khẩu, Xác nhận
      expect(find.widgetWithText(ElevatedButton, 'Đăng ký tài khoản'),
          findsOneWidget);
    });
  });
}
