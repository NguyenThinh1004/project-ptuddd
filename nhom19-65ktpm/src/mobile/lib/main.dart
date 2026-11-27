import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/discipline_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'views/auth/home_preview_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/splash_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DisciplineProvider()),
      ],
      child: const StudyMateApp(),
    ),
  );
}

/// Ứng dụng chính StudyMate AI
/// Màn hình chính mặc định hiển thị thẳng vào Dashboard cá nhân (Kỷ luật, Streak, Heatmap)
class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'StudyMate AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Màn hình chính hiển thị thẳng vào Dashboard cá nhân
      initialRoute: '/dashboard',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePreviewScreen(),
      },
    );
  }
}
