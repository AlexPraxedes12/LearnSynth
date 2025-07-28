import 'package:flutter/material.dart';

import 'constants.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/add_content_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/pdf_picker_screen.dart';
import 'screens/audio_recorder_screen.dart';
import 'screens/video_picker_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/method_selection_screen.dart';
import 'screens/deep_understanding_screen.dart';
import 'screens/memorization_screen.dart';
import 'screens/contextual_association_screen.dart';
import 'screens/interactive_evaluation_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/text_input_screen.dart';
import 'screens/preview_screen.dart';
import 'package:provider/provider.dart';
import 'content_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ContentProvider(),
      child: const StudyApp(),
    ),
  );
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Learning App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: Routes.home,
      routes: {
        // Map each named route to its corresponding screen. Note that
        // it’s important to keep this list in sync with the definitions
        // in constants.dart. Also avoid using replacement navigation in
        // the routes table.
        Routes.home: (_) => const MainNavigation(),
        Routes.addContent: (_) => const AddContentScreen(),
        Routes.textInput: (_) => const TextInputScreen(),
        Routes.pdfPicker: (_) => const PdfPickerScreen(),
        Routes.audioRecorder: (_) => const AudioRecorderScreen(),
        Routes.videoPicker: (_) => const VideoPickerScreen(),
        Routes.projects: (_) => const ProjectsScreen(),
        Routes.preview: (context) {
          final text = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return PreviewScreen(text: text);
        },
        Routes.loading: (context) {
          final text = ModalRoute.of(context)?.settings.arguments as String?;
          return LoadingScreen(text: text);
        },
        Routes.analysis: (_) => const AnalysisScreen(),
        Routes.methodSelection: (_) => const MethodSelectionScreen(),
        Routes.deepUnderstanding: (_) => const DeepUnderstandingScreen(),
        Routes.memorization: (_) => const MemorizationScreen(),
        Routes.contextualAssociation: (_) => const ContextualAssociationScreen(),
        Routes.interactiveEvaluation: (_) => const InteractiveEvaluationScreen(),
        Routes.progress: (_) => const ProgressScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    ProgressScreen(),
    PlaceholderScreen(title: 'Library'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppTheme.background,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Library'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Page',
        style: const TextStyle(fontSize: 24, color: Colors.white70),
      ),
    );
  }
}