import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.startStudySession('flash');
    });
  }

  @override
  void dispose() {
    _provider.endStudySession('flash');
    // Don't update progress during dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final p = context.watch<ContentProvider>();
    final cards = p.flashcards;
    final i = p.flashIndex;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.flashcardsTitle),
        actions: const [SettingsButton()],
      ),
      body: cards.isEmpty
          ? Center(child: Text(app.noFlashcards))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${app.term}: ${cards[i].term}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('${app.definition}: ${cards[i].definition}'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: i > 0
                              ? () {
                                  final newIndex = i - 1;
                                  p.setFlashIndex(newIndex);
                                  p.updateMethodProgress(
                                      'flash', newIndex / cards.length);
                                }
                              : null,
                          child: Text(app.prev),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: i < cards.length - 1
                              ? () {
                                  final newIndex = i + 1;
                                  p.setFlashIndex(newIndex);
                                  p.updateMethodProgress(
                                      'flash', newIndex / cards.length);
                                }
                              : null,
                          child: Text(app.next),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
