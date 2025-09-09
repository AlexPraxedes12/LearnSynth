import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'ui/theme.dart';
import 'ui/theme_controller.dart';
import 'screens/add_content_screen.dart';
import 'screens/analyzing_screen.dart';
import 'screens/pdf_picker_screen.dart';
import 'screens/audio_picker_screen.dart';
import 'screens/video_picker_screen.dart';
import 'screens/library_screen.dart';
import 'screens/method_selection_screen.dart';
import 'screens/deep_understanding_screen.dart';
import 'screens/memorization_screen.dart';
import 'screens/contextual_association_screen.dart';
import 'screens/interactive_evaluation_screen.dart';
import 'screens/cloze_drill_screen.dart';
import 'screens/progress/progress_page.dart';
import 'screens/text_input_screen.dart';
import 'content_provider.dart';
import 'providers/settings_provider.dart';
import 'debug/offline_smoke_test.dart';
import 'core/llm/llm_service.dart';
import 'widgets/tutorial_overlay.dart';
import 'core/net/custom_http_overrides.dart';
import 'core/net/backend_client.dart';
import 'core/net/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initCustomHttpOverrides();
  await Hive.initFlutter();
  await Hive.openBox<Map>('learnpacks');
  await LlmService.I.init();
  // Warm up backend to avoid cold-start delays.
  unawaited(
    BackendClient.get(Uri.parse('${ApiConfig.apiBase}/health')).catchError((_) {}),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: LlmService.I),
      ],
      child: const StudyApp(),
    ),
  );
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'Interactive Learning App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.mode,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: Routes.home,
      routes: {
        Routes.home: (_) => const MainNavigation(),
        Routes.textInput: (_) => TextInputScreen(),
        Routes.pdfPicker: (_) => const PdfPickerScreen(),
        Routes.audio: (_) => const AudioPickerScreen(),
        Routes.videoPicker: (_) => const VideoPickerScreen(),
        Routes.library: (_) => const LibraryScreen(),
        AppRoutes.analyzing: (_) => const AnalyzingScreen(),
        AppRoutes.studyPack: (_) => const MethodSelectionScreen(),
        Routes.methodSelection: (_) => const MethodSelectionScreen(),
        Routes.deep: (_) => const DeepUnderstandingScreen(),
        Routes.memorization: (_) => const MemorizationScreen(),
        Routes.concept: (_) => const ContextualAssociationScreen(),
        Routes.quiz: (_) => const InteractiveEvaluationScreen(),
        Routes.cloze: (_) => const ClozeDrillScreen(),
        Routes.progress: (_) => const ProgressPage(),
        if (kDebugMode)
          '/debug/offline-llm-smoke': (_) => const OfflineSmokeTest(),
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
  final List<Widget> _screens = [
    AddContentScreen(),
    const ProgressPage(),
    const LibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboardingShown') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showOnboardingTutorial(context);
        await prefs.setBool('onboardingShown', true);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.6),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.add),
            label: app?.add ?? 'Add',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: app?.progress ?? 'Progress',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: app?.library ?? 'Library',
          ),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        '$title Page',
        style: TextStyle(
          fontSize: 24,
          color: scheme.onBackground.withOpacity(0.7),
        ),
      ),
    );
  }
}
