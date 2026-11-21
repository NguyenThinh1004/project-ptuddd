import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/speech_provider.dart';
import 'providers/study_provider.dart';
import 'screens/flashcard_3d_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/speech_assessment_screen.dart';
import 'screens/subjects_screen.dart';
import 'services/ai_audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartLearningApp());
}

class SmartLearningApp extends StatefulWidget {
  const SmartLearningApp({super.key});

  @override
  State<SmartLearningApp> createState() => _SmartLearningAppState();
}

class _SmartLearningAppState extends State<SmartLearningApp> {
  late final AiAudioService _aiAudioService;

  @override
  void initState() {
    super.initState();
    _aiAudioService = AiAudioService();
  }

  @override
  void dispose() {
    _aiAudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpeechProvider(_aiAudioService)),
        ChangeNotifierProvider(create: (_) => StudyProvider(_aiAudioService)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Speech & Smart Learning',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const SmartLearningHome(),
      ),
    );
  }
}

class SmartLearningHome extends StatefulWidget {
  const SmartLearningHome({super.key});

  @override
  State<SmartLearningHome> createState() => _SmartLearningHomeState();
}

class _SmartLearningHomeState extends State<SmartLearningHome> {
  int currentTab = 0;

  final List<Widget> pages = const [
    SpeechAssessmentScreen(),
    Flashcard3DScreen(),
    QuizScreen(),
    SubjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (idx) => setState(() => currentTab = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mic), label: 'Phát âm'),
          NavigationDestination(icon: Icon(Icons.style), label: 'Flashcards'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'Quiz'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Môn học'),
        ],
      ),
    );
  }
}
