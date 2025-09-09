import 'package:flutter/material.dart';

/// Data model for a single tutorial card.
class _TutorialCard {
  final IconData? icon;
  final String title;
  final String description;
  const _TutorialCard({this.icon, required this.title, required this.description});
}

/// Shows the onboarding tutorial as a modal dialog overlay.
Future<void> showOnboardingTutorial(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TutorialDialog(),
  );
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_TutorialCard> _cards = const [
    _TutorialCard(
      icon: Icons.school,
      title: 'Welcome to LearnSynth',
      description:
          'Turn your text, PDFs, audio, or video into interactive courses.',
    ),
    _TutorialCard(
      icon: Icons.paste,
      title: 'Paste Text',
      description: 'Quickly start from plain text.',
    ),
    _TutorialCard(
      icon: Icons.picture_as_pdf,
      title: 'Upload PDF',
      description: 'Import a PDF document.',
    ),
    _TutorialCard(
      icon: Icons.audiotrack,
      title: 'Upload Audio',
      description: 'Transcribe an audio file.',
    ),
    _TutorialCard(
      icon: Icons.videocam,
      title: 'Upload Video',
      description: 'Transcribe a video.',
    ),
    _TutorialCard(
      icon: Icons.book,
      title: 'Library & Progress',
      description:
          'Find saved courses in the Library tab and track progress in the Progress tab.',
    ),
    _TutorialCard(
      icon: Icons.info,
      title: 'Tip',
      description:
          'Courses are saved locally. Export if you want to back them up.',
    ),
  ];

  void _next() {
    if (_index < _cards.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_index > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _skip() {
    Navigator.of(context).pop();
  }

  void _done() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _cards.length - 1;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _skip, child: const Text('Skip')),
            ),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _controller,
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final card = _cards[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (card.icon != null)
                        Icon(card.icon, size: 64, color: scheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        card.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card.description,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _index == 0 ? null : _back,
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: isLast ? _done : _next,
                  child: Text(isLast ? 'Done' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

