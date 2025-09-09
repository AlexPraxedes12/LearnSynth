import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import '../widgets/tutorial_overlay.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final app = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(app.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(app.language),
                const SizedBox(width: 16),
                DropdownButton<Locale>(
                  value: settings.locale,
                  items: [
                    DropdownMenuItem(
                        value: const Locale('en'), child: Text(app.english)),
                    DropdownMenuItem(
                        value: const Locale('es'), child: Text(app.spanish)),
                    DropdownMenuItem(
                        value: const Locale('fr'), child: Text(app.french)),
                  ],
                  onChanged: (loc) {
                    if (loc != null) {
                      settings.setLocale(loc);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboardingShown', false);
                if (context.mounted) {
                  await showOnboardingTutorial(context);
                  await prefs.setBool('onboardingShown', true);
                }
              },
              child: const Text('Show tutorial again'),
            ),
          ],
        ),
      ),
    );
  }
}

