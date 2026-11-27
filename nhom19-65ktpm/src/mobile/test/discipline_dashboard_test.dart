import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/discipline_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/views/dashboard/dashboard_screen.dart';
import 'package:mobile/views/dashboard/widgets/date_selector_strip.dart';
import 'package:mobile/views/dashboard/widgets/daily_goal_progress_ring.dart';
import 'package:mobile/views/dashboard/widgets/monthly_heatmap_grid.dart';
import 'package:mobile/views/dashboard/widgets/streak_card.dart';
import 'package:provider/provider.dart';

void main() {
  group('DisciplineProvider Unit Tests', () {
    test('Initial state reflects 7 days streak and 25/30 minutes', () {
      final provider = DisciplineProvider();
      expect(provider.currentStreak, 7);
      expect(provider.longestStreak, 14);
      expect(provider.dailyGoalMinutes, 30);
      expect(provider.todayMinutesLearned, 25);
      expect(provider.todayProgressPercent, 83);
      expect(provider.isTodayGoalCompleted, isFalse);
      expect(provider.remainingMinutesToday, 5);
    });

    test('completeStudySession increments minutes and reactive streak updates (Acceptance Criteria)', () {
      final provider = DisciplineProvider();
      expect(provider.currentStreak, 7);
      expect(provider.isTodayGoalCompleted, isFalse);

      // Hoàn thành phiên học 25 phút
      provider.completeStudySession(
        minutes: 25,
        subject: 'Focus Pomodoro',
      );

      // Số phút hôm nay tăng lên 25 + 25 = 50 phút
      expect(provider.todayMinutesLearned, 50);
      expect(provider.isTodayGoalCompleted, isTrue);
      expect(provider.todayProgressPercent, 167);

      // Streak tự động tăng lên 8 ngày phản ứng theo thời gian thực!
      expect(provider.currentStreak, 8);
      expect(provider.hasIncreasedStreakToday, isTrue);

      // Gọi tiếp lần nữa trong cùng ngày không tăng thêm streak trùng lặp
      provider.completeStudySession(minutes: 10);
      expect(provider.todayMinutesLearned, 60);
      expect(provider.currentStreak, 8);
    });

    test('Monthly Heatmap records contain 30 days with valid contribution levels', () {
      final provider = DisciplineProvider();
      final records = provider.getMonthlyHeatmapRecords(30);

      expect(records.length, 30);
      for (final record in records) {
        expect(record.level, inInclusiveRange(0, 4));
        expect(record.minutes, greaterThanOrEqualTo(0));
      }

      // Hôm nay có 25 phút học -> Level 2 (16 - 30 phút)
      expect(records.last.minutes, 25);
      expect(records.last.level, 2);
    });

    test('Date selector selects different day and generates 7 days of week', () {
      final provider = DisciplineProvider();
      final weekDates = provider.getWeekDatesForSelectedDate();
      expect(weekDates.length, 7);

      final targetDate = DateTime(2026, 11, 20);
      provider.setSelectedDate(targetDate);
      expect(provider.selectedDate.year, 2026);
      expect(provider.selectedDate.month, 11);
      expect(provider.selectedDate.day, 20);

      provider.goToToday();
      final now = DateTime.now();
      expect(provider.selectedDate.day, now.day);
    });
  });

  group('Discipline Dashboard Widget Tests & Responsiveness', () {
    Widget createDashboardTestApp({DisciplineProvider? customDiscipline}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => customDiscipline ?? DisciplineProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const DashboardScreen(),
            );
          },
        ),
      );
    }

    testWidgets('StreakCard displays flame icon and 7 days streak', (tester) async {
      final discipline = DisciplineProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: discipline),
          ],
          child: const MaterialApp(
            home: Scaffold(body: StreakCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7 Ngày'), findsOneWidget);
      expect(find.text('Streak 🔥'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.text('Kỷ lục chuỗi: 14 ngày'), findsOneWidget);
    });

    testWidgets('DailyGoalProgressRing displays 25/30 minutes and 83%', (tester) async {
      final discipline = DisciplineProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: discipline),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DailyGoalProgressRing()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('83'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      expect(find.text('25 / 30 phút'), findsWidgets);
      expect(find.text('Mục tiêu học hôm nay'), findsOneWidget);
    });

    testWidgets('DateSelectorStrip displays horizontal days and handles tapping', (tester) async {
      final discipline = DisciplineProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: discipline),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DateSelectorStrip()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('T2'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
      expect(find.byType(DateSelectorStrip), findsOneWidget);
    });

    testWidgets('MonthlyHeatmapGrid renders 30 contribution cells without overflow', (tester) async {
      final discipline = DisciplineProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: discipline),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: MonthlyHeatmapGrid())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bản đồ nhiệt độ học tập (30 ngày)'), findsOneWidget);
      expect(find.text('Phong cách GitHub Contribution'), findsOneWidget);
      expect(find.text('Ít'), findsOneWidget);
      expect(find.text('Nhiều'), findsOneWidget);
    });

    testWidgets('DashboardScreen full view updates streak and progress when completing session (Acceptance Criteria)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final discipline = DisciplineProvider();
      await tester.pumpWidget(createDashboardTestApp(customDiscipline: discipline));
      await tester.pumpAndSettle();

      // Kiểm tra trạng thái ban đầu: 7 ngày, 83%, 25/30 phút
      expect(find.text('7 Ngày'), findsOneWidget);
      expect(find.text('83'), findsOneWidget);

      // Bấm nút "Hoàn thành 1 phiên học (+25 phút)"
      final completeButton = find.widgetWithText(
        ElevatedButton,
        'Hoàn thành 1 phiên học (+25 phút)',
      );
      expect(completeButton, findsOneWidget);

      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      // Kiểm tra phản ứng thời gian thực ngay lập tức trên UI:
      // Streak cập nhật lên 8 Ngày!
      expect(find.text('8 Ngày'), findsOneWidget);
      // Số phút học hôm nay đã tăng lên 50 phút
      expect(find.text('50 / 30 phút'), findsWidgets);
      // Hiển thị thông báo SnackBar chúc mừng
      expect(find.byType(SnackBar), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
