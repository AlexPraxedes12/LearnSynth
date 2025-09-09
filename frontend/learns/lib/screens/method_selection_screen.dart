import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';
import '../widgets/theme_toggle_button.dart';

class MethodSelectionScreen extends StatefulWidget {
  const MethodSelectionScreen({super.key});

  @override
  State<MethodSelectionScreen> createState() => _MethodSelectionScreenState();
}

class _MethodSelectionScreenState extends State<MethodSelectionScreen> {
  late final ContentProvider _provider;

  void _navigateWithTimer(String route) {
    _provider.startCourseTimer(_provider.packId);
    Navigator.pushNamed(context, route)
        .then((_) => _provider.stopCourseTimer());
  }

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_provider.justSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study pack saved automatically')),
        );
        _provider.clearJustSaved();
      }
    });
  }

  @override
  void dispose() {
    // Reset provider after the widget is fully disposed to avoid triggering
    // notifications while the widget tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.resetAll();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final hasFlash = p.flashcards.isNotEmpty;
    final canConcept = p.canConcept;
    final hasQuiz = p.quizzes.isNotEmpty;
    final hasCloze =
        p.cloze.isNotEmpty && p.cloze.every((c) => c.options.isNotEmpty);
    final canDeep = p.deepPrompts.isNotEmpty;
    final app = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.studyPack),
        actions: const [
          ThemeToggleButton(),
          SettingsButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(app.summary, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              p.summary ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            WideButton(
              label: app.memorizationFlashcards,
              enabled: hasFlash,
              onPressed: hasFlash
                  ? () => _navigateWithTimer(Routes.memorization)
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.deepUnderstanding,
              enabled: canDeep,
              onPressed:
                  canDeep ? () => _navigateWithTimer(Routes.deep) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.contextualAssociation,
              enabled: canConcept,
              onPressed: canConcept
                  ? () {
                      final cp = context.read<ContentProvider>();
                      if (cp.canConcept) {
                        _navigateWithTimer(Routes.concept);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.interactiveEvaluation,
              enabled: hasQuiz,
              onPressed:
                  hasQuiz ? () => _navigateWithTimer(Routes.quiz) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.clozeDrills,
              enabled: hasCloze,
              onPressed:
                  hasCloze ? () => _navigateWithTimer(Routes.cloze) : null,
            ),
          ],
        ),
      ),
    );
  }
}
