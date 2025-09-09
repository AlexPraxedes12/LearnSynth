import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';
import '../core/progress/progress_service.dart';

class InteractiveEvaluationScreen extends StatefulWidget {
  const InteractiveEvaluationScreen({super.key});
  @override
  State<InteractiveEvaluationScreen> createState() => _InteractiveEvaluationScreenState();
}

class _InteractiveEvaluationScreenState extends State<InteractiveEvaluationScreen> {
  int i = 0, score = 0, selected = -1;
  ProgressService? _ps;
  late final String _courseId;
  final _sw = Stopwatch();
  Timer? _timer;
  int _elapsedSeconds = 0;
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    final p = context.read<ContentProvider>();
    _provider = p;
    _courseId = p.packId;
    final items = p.quizzes;
    ProgressService.create().then((s) {
      s.startRun(_courseId, totalItems: items.length);
      setState(() => _ps = s);
    });
    _sw.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds = _sw.elapsed.inSeconds);
    });
    _provider.startStudySession('quiz');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sw.stop();
    _ps?.addTime(_courseId, _sw.elapsedMilliseconds);
    _provider.endStudySession('quiz');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final p = context.watch<ContentProvider>();
    final items = p.quizzes;
    final q = items[i];
    final prog = _ps?.get(_courseId);

    return Scaffold(
      appBar: AppBar(
        title: Text(app.quizTitle),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prog != null) ...[
              LinearProgressIndicator(value: prog.pct),
              Text('Progreso: ${(prog.pct * 100).toStringAsFixed(0)}%  •  Acierto: ${(prog.accuracy * 100).toStringAsFixed(0)}%  •  Tiempo: ${(_elapsedSeconds ~/ 60)}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')} min'),
              const SizedBox(height: 16),
            ],
            Text(app.questionOf(i + 1, items.length),
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final idx in List.generate(q.options.length, (x) => x))
              RadioListTile<int>(
                value: idx,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
                title: Text(q.options[idx]),
              ),
            const Spacer(),
            WideButton(
              label: i == items.length - 1 ? app.finish : app.next,
              enabled: selected != -1,
              onPressed: () {
                final correct = selected == q.answerIndex;
                if (correct) score++;
                _ps?.recordAnswer(_courseId, correct: correct);
                final progVal = (i + 1) / items.length;
                p.updateMethodProgress('quiz', progVal);
                if (i == items.length - 1) {
                  p.saveQuizScore(score);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(app.results),
                      content: Text(app.score(score, items.length)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == '/studyPack'),
                          child: Text(app.close),
                        ),
                      ],
                    ),
                  );
                } else {
                  setState(() { i++; selected = -1; });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
