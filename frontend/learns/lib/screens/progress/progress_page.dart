import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../content_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_button.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String? _selectedPackId;

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final app = AppLocalizations.of(context)!;
    final cp = context.watch<ContentProvider>();

    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>('learnpacks').listenable(),
      builder: (_, __, ___) {
        final packs = cp.listPacks();
        final hasData = cp.totalStudyTime != 0 || packs.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(app.progress),
            actions: const [SettingsButton()],
          ),
          body: !hasData
              ? Center(child: Text(app.startStudyingMessage))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildOverallStats(
                              context, app, cp, packs.length, _selectedPackId),
                          const SizedBox(height: 16),
                          _buildMethodProgress(context, cp, _selectedPackId),
                          if (packs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildRecentPacks(context, app, packs, cp),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOverallStats(BuildContext context, AppLocalizations app,
      ContentProvider cp, int packCount, String? packId) {
    final overall = packId == null
        ? cp.overallCumulativeProgress
        : cp.getPackOverallProgress(packId);
    final studyTime =
        packId == null ? cp.totalStudyTime : cp.getStudyTimeForPack(packId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.overallProgress,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: overall),
            Text('${(overall * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(_formatDuration(studyTime)),
                    Text(app.studyTime, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('${cp.completedSessions}'),
                    Text(app.sessions, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('$packCount'),
                    Text(app.packs, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodProgress(
      BuildContext context, ContentProvider cp, String? packId) {
    final app = AppLocalizations.of(context)!;
    double progress(String method) => packId == null
        ? cp.getCumulativeMethodProgress(method)
        : cp.getMethodProgressForPack(packId, method);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.methodProgress,
                style: Theme.of(context).textTheme.titleMedium),
            _MethodProgressBar(app.memorization, progress('flash')),
            _MethodProgressBar(app.deepUnderstanding, progress('deep')),
            _MethodProgressBar(app.conceptMap, progress('concept')),
            _MethodProgressBar(app.quiz, progress('quiz')),
            _MethodProgressBar(app.clozeDrillsTitle, progress('cloze')),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPacks(BuildContext context, AppLocalizations app,
      List<Map<String, dynamic>> packs, ContentProvider cp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.recentStudyPacks,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...packs.take(5).map(
              (pack) {
                final packId = pack['id']?.toString();
                final isSelected = packId == _selectedPackId;
                return ListTile(
                  title: Text(
                    packId != null ? cp.getPackDisplayName(packId) : '',
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Text(_formatDate(pack['createdAt'])),
                  trailing: Text('${(pack['progress'] ?? 0)}%'),
                  onTap: () {
                    setState(() {
                      _selectedPackId = packId;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return '';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _MethodProgressBar extends StatelessWidget {
  final String label;
  final double value;
  const _MethodProgressBar(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          LinearProgressIndicator(value: value),
          Text('${(value * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

