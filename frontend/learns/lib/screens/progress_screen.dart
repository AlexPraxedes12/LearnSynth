import 'package:flutter/material.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import '../widgets/quote_card.dart';
import '../widgets/settings_button.dart';

/// Displays summary statistics for the user’s progress. Navigation back
/// to the home page is provided by the bottom navigation bar, so we
/// simply show a motivational quote instead of a button.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.progress),
        actions: const [SettingsButton()],
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            QuoteCard(quote: app.progressTrackingNotImplemented),
          ],
        ),
      ),
    );
  }
}
