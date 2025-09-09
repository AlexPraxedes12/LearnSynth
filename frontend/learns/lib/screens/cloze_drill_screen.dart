import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../content_provider.dart';
import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';

class ClozeDrillScreen extends StatefulWidget {
  const ClozeDrillScreen({super.key});

  @override
  State<ClozeDrillScreen> createState() => _ClozeDrillScreenState();
}

class _ClozeDrillScreenState extends State<ClozeDrillScreen> {
  int i = 0;
  int? selected;
  bool showExplanation = false;
  int score = 0;
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    _provider.startStudySession('cloze');
  }

  @override
  void dispose() {
    _provider.endStudySession('cloze');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final p = context.watch<ContentProvider>();
    final items = p.cloze;
    final item = items[i];
    final sentence = item.sentence;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.clozeDrillsTitle),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${i + 1} / ${items.length}', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(sentence, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final idx in List.generate(item.options.length, (x) => x))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: selected == null ? () => setState(() => selected = idx) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == idx
                        ? (idx == item.answerIndex ? Colors.green : Colors.red)
                        : null,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.options[idx]),
                  ),
                ),
              ),
            if (selected != null && !showExplanation)
              TextButton(
                onPressed: () => setState(() => showExplanation = true),
                child: Text(app.showExplanation),
              ),
            if (showExplanation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${app.answer}: '
                    '${sentence.replaceFirst('___', item.options[item.answerIndex])}'),
              ),
            const Spacer(),
            WideButton(
              label: i == items.length - 1 ? app.finish : app.next,
              enabled: selected != null,
              onPressed: () {
                if (selected == item.answerIndex) score++;
                final next = i + 1;
                _provider.updateMethodProgress('cloze', next / items.length);
                if (i == items.length - 1) {
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
                  setState(() {
                    i = next;
                    selected = null;
                    showExplanation = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
