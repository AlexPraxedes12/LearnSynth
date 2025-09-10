import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import '../content_provider.dart';
import '../constants.dart';
import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';
import '../providers/settings_provider.dart';
import '../core/llm/offline_tasks.dart';
import '../core/llm/llm_router.dart';
import '../core/llm/providers_local.dart';
import '../core/llm/providers_backend.dart';
import '../core/net/api_config.dart';
import '../config/env.dart';

class _RouterProvider implements LLMProvider {
  final LLMRouter router;
  _RouterProvider(this.router);
  @override
  String get id => 'router';

  @override
  Stream<String> stream(String prompt,
      {int maxTokens = 256, double temperature = .2}) {
    return router.stream(prompt, maxTokens: maxTokens, temperature: temperature);
  }
}

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  void _navigateWithTimer(BuildContext context, String route) {
    final cp = context.read<ContentProvider>();
    cp.startCourseTimer(cp.packId);
    Navigator.pushNamed(context, route).then((_) => cp.stopCourseTimer());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final p = context.watch<ContentProvider>();
    final settings = context.watch<SettingsProvider>();
    final llmRouter = LLMRouter(
      offlinePref: () => Env.enableOfflineLLM && settings.enableOfflineLLM,
      local: LocalOfflineLLMProvider(),
      backend: BackendLLMProvider(ApiConfig.apiBase),
    );
    final hasFlash = p.flashcards.isNotEmpty;
    final canConcept = p.canConcept;
    final hasQuiz = p.quizzes.isNotEmpty;
    final hasCloze = p.cloze.isNotEmpty;
    final canDeep = p.deepPrompts.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.studyPack),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (p.summary?.isNotEmpty ?? false) ...[
              Text(
                app.summary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                p.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
            ],
            WideButton(
              label: app.memorizationFlashcards,
              enabled: hasFlash,
              onPressed:
                  hasFlash ? () => _navigateWithTimer(context, Routes.memorization) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.deepUnderstanding,
              enabled: canDeep,
              onPressed:
                  canDeep ? () => _navigateWithTimer(context, Routes.deep) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.contextualAssociation,
              enabled: canConcept,
              onPressed: canConcept
                  ? () {
                      final cp = context.read<ContentProvider>();
                      if (cp.canConcept) {
                        _navigateWithTimer(context, Routes.concept);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.interactiveEvaluation,
              enabled: hasQuiz,
              onPressed:
                  hasQuiz ? () => _navigateWithTimer(context, Routes.quiz) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: app.clozeDrills,
              enabled: hasCloze,
              onPressed:
                  hasCloze ? () => _navigateWithTimer(context, Routes.cloze) : null,
            ),
            if (Env.enableOfflineLLM && settings.enableOfflineLLM) ...[
              const SizedBox(height: 12),
              WideButton(
                label: 'Resumen offline',
                onPressed: () async {
                  final routerProvider = _RouterProvider(llmRouter);
                  try {
                    final summary = await offlineSummarize(
                      routerProvider,
                      p.content ?? '',
                    );
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Resumen'),
                        content: Text(
                          summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
              const SizedBox(height: 12),
              WideButton(
                label: 'Flashcards offline',
                onPressed: () async {
                  final routerProvider = _RouterProvider(llmRouter);
                  try {
                    final cards = await offlineFlashcards(
                      routerProvider,
                      p.content ?? '',
                    );
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Flashcards'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: cards
                                .map(
                                  (c) => ListTile(
                                    title: Text(c['q'] ?? ''),
                                    subtitle: Text(c['a'] ?? ''),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
