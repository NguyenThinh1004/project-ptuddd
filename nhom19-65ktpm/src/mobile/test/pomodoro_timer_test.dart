import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/discipline_provider.dart';
import 'package:mobile/providers/pomodoro_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/services/pomodoro_alarm_player.dart';
import 'package:mobile/services/pomodoro_database_helper.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/views/pomodoro/pomodoro_screen.dart';
import 'package:mobile/views/pomodoro/widgets/circular_timer_widget.dart';
import 'package:mobile/views/pomodoro/widgets/distraction_lock_view.dart';
import 'package:mobile/views/pomodoro/widgets/timer_controls.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _FakeWakelockPlatform extends WakelockPlusPlatformInterface {
  final List<bool> toggles = [];

  @override
  Future<void> toggle({required bool enable}) async {
    toggles.add(enable);
  }

  @override
  Future<bool> get enabled async => toggles.isNotEmpty && toggles.last;
}

class _FakePomodoroAlarmPlayer implements PomodoroAlarmPlayer {
  int playCount = 0;

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('PomodoroProvider Unit Tests', () {
    test('Initial state is 25 minutes focus mode', () {
      final pomodoro = PomodoroProvider();
      expect(pomodoro.currentMode, PomodoroMode.focus);
      expect(pomodoro.remainingSeconds, 25 * 60);
      expect(pomodoro.totalSeconds, 25 * 60);
      expect(pomodoro.formattedTime, '25:00');
      expect(pomodoro.isRunning, isFalse);
      expect(pomodoro.isPaused, isFalse);
    });

    test('startTimer, pauseTimer, resumeTimer and resetTimer', () async {
      final pomodoro = PomodoroProvider();

      pomodoro.startTimer();
      expect(pomodoro.isRunning, isTrue);
      expect(pomodoro.isPaused, isFalse);

      pomodoro.pauseTimer();
      expect(pomodoro.isRunning, isTrue);
      expect(pomodoro.isPaused, isTrue);

      pomodoro.resumeTimer();
      expect(pomodoro.isRunning, isTrue);
      expect(pomodoro.isPaused, isFalse);

      pomodoro.resetTimer();
      expect(pomodoro.isRunning, isFalse);
      expect(pomodoro.isPaused, isFalse);
      expect(pomodoro.remainingSeconds, 25 * 60);
      expect(pomodoro.formattedTime, '25:00');
    });

    test('switchMode updates mode and resets countdown to respective duration',
        () {
      final pomodoro = PomodoroProvider();

      // Nghỉ ngắn: 5 phút
      pomodoro.switchMode(PomodoroMode.shortBreak);
      expect(pomodoro.currentMode, PomodoroMode.shortBreak);
      expect(pomodoro.remainingSeconds, 5 * 60);
      expect(pomodoro.formattedTime, '05:00');

      // Nghỉ dài: 15 phút
      pomodoro.switchMode(PomodoroMode.longBreak);
      expect(pomodoro.currentMode, PomodoroMode.longBreak);
      expect(pomodoro.remainingSeconds, 15 * 60);
      expect(pomodoro.formattedTime, '15:00');

      // Quay lại tập trung: 25 phút
      pomodoro.switchMode(PomodoroMode.focus);
      expect(pomodoro.currentMode, PomodoroMode.focus);
      expect(pomodoro.remainingSeconds, 25 * 60);
      expect(pomodoro.formattedTime, '25:00');
    });

    test('updateSettings modifies custom durations', () {
      final pomodoro = PomodoroProvider();

      pomodoro.updateSettings(
        focusMinutes: 30,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
        soundEnabled: false,
        distractionLock: true,
      );

      expect(pomodoro.focusDurationMinutes, 30);
      expect(pomodoro.shortBreakDurationMinutes, 10);
      expect(pomodoro.longBreakDurationMinutes, 20);
      expect(pomodoro.isSoundEnabled, isFalse);
      expect(pomodoro.isDistractionLockEnabled, isTrue);
      expect(pomodoro.formattedTime, '30:00');
    });

    test(
        'Countdown completion saves to SQLite and updates DisciplineProvider (Acceptance Criteria)',
        () async {
      final discipline = DisciplineProvider();
      final initialStreak = discipline.currentStreak;
      final alarmPlayer = _FakePomodoroAlarmPlayer();
      final pomodoro = PomodoroProvider(
        disciplineProvider: discipline,
        alarmPlayer: alarmPlayer,
      );

      // Đặt 1 giây cuối để test hoàn thành
      pomodoro.setRemainingSecondsForTesting(1);
      pomodoro.startTimer();

      // Đợi timer tick 1 giây
      await Future.delayed(const Duration(milliseconds: 1200));

      // Kiểm tra tự động lưu SQLite
      final sessions = await PomodoroDatabaseHelper.instance.getAllSessions();
      expect(sessions.isNotEmpty, isTrue);

      // Kiểm tra DisciplineProvider được cập nhật
      expect(discipline.todayMinutesLearned, greaterThan(25));
      expect(alarmPlayer.playCount, 1);
      pomodoro.dispose();
    });

    test('Disabling sound prevents alarm playback when timer expires',
        () async {
      final alarmPlayer = _FakePomodoroAlarmPlayer();
      final pomodoro = PomodoroProvider(alarmPlayer: alarmPlayer);
      pomodoro.updateSettings(soundEnabled: false);
      pomodoro.setRemainingSecondsForTesting(1);
      pomodoro.startTimer();

      await Future.delayed(const Duration(milliseconds: 1200));

      expect(alarmPlayer.playCount, 0);
      pomodoro.dispose();
    });
  });

  group('PomodoroDatabaseHelper Tests', () {
    test('insertSession and getAllSessions work correctly', () async {
      final helper = PomodoroDatabaseHelper.instance;
      await helper.initDatabase();

      final record = PomodoroRecord(
        mode: 'focus',
        durationMinutes: 25,
        completedAt: DateTime.now(),
        quote: 'Thử nghiệm tập trung',
      );

      final id = await helper.insertSession(record);
      expect(id, greaterThan(0));

      final allSessions = await helper.getAllSessions();
      expect(allSessions.any((s) => s.quote == 'Thử nghiệm tập trung'), isTrue);
    });
  });

  group('Pomodoro Widget & UI Tests', () {
    Widget createPomodoroTestApp({PomodoroProvider? customPomodoro}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DisciplineProvider()),
          ChangeNotifierProvider(
              create: (_) => customPomodoro ?? PomodoroProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const PomodoroScreen(),
            );
          },
        ),
      );
    }

    testWidgets('CircularTimerWidget displays formatted time and mode badge',
        (tester) async {
      final pomodoro = PomodoroProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: pomodoro),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CircularTimerWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Phiên Tập Trung'), findsOneWidget);
    });

    testWidgets('TimerControls toggles Start and Pause', (tester) async {
      final pomodoro = PomodoroProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: pomodoro),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TimerControls(onOpenSettings: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

      // Bấm nút Start
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(pomodoro.isRunning, isTrue);
    });

    testWidgets(
        'DistractionLockView manages wakelock and displays rotating quotes',
        (tester) async {
      final previousPlatform = wakelockPlusPlatformInstance;
      final wakelockPlatform = _FakeWakelockPlatform();
      wakelockPlusPlatformInstance = wakelockPlatform;
      addTearDown(() {
        wakelockPlusPlatformInstance = previousPlatform;
      });

      final pomodoro = PomodoroProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: pomodoro),
          ],
          child: MaterialApp(
            home: DistractionLockView(onUnlock: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khóa Xao Nhãng Đang Bật'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
      expect(wakelockPlatform.toggles, [true]);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(wakelockPlatform.toggles, [true, false, true]);

      final initialQuote = pomodoro.currentQuote;
      await tester.tap(find.text(initialQuote));
      await tester.pump();
      expect(pomodoro.currentQuote, isNot(initialQuote));
      expect(find.text(pomodoro.currentQuote), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(wakelockPlatform.toggles.last, isFalse);
    });

    testWidgets('PomodoroScreen renders properly without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createPomodoroTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Đồng Hồ Focus Pomodoro'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Nhật Ký Phiên Học SQLite'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
