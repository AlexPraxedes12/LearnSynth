import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});
  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final provider = context.read<ContentProvider>();
    try {
      final ok = await provider.runAnalysis(context);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed(Routes.studyPack);
      } else {
        final err = provider.lastError;
        final app = AppLocalizations.of(context)!;
        final base = app.analyzeFailed;
        final msg = (err != null && err.contains('Network error'))
            ? 'Esperando conexión con el servidor...'
            : err == 'file_too_large'
                ? app.fileTooLarge
                : err?.isNotEmpty == true
                    ? '$base: $err'
                    : base;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      final app = AppLocalizations.of(context)!;
      final base = app.analyzeFailed;
      final emsg = e.toString();
      final msg = emsg.contains('Network error')
          ? 'Esperando conexión con el servidor...'
          : emsg.contains('file_too_large')
              ? app.fileTooLarge
              : '$base: $emsg';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.analyzingTitle),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 44, child: Center(child: Text(app.analyzingDots))),
      ),
    );
  }
}
