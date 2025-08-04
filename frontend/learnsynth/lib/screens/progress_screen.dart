import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../content_provider.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/quote_card.dart';

/// Displays summary statistics for the user’s progress. Navigation back
/// to the home page is provided by the bottom navigation bar, so we
/// simply show a motivational quote instead of a button.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  /// Fetches progress stats for the current content.
  Future<Map<String, dynamic>> _fetchProgress(BuildContext context) async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    try {
      final url = Uri.parse('http://10.0.2.2:8000/progress');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.content ?? ''}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'completedSessions': data['completedSessions'] ?? 0,
          'studyTime': data['studyTime'] ?? '0m',
          'methodsUsed': data['methodsUsed'] ?? 0,
        };
      } else {
        throw Exception('Failed to load progress');
      }
    } catch (_) {
      throw Exception('Failed to load progress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProgress(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Could not load progress',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
            );
          }
          final progress = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                ProgressSummaryCard(
                  title: 'Completed Sessions',
                  value: '${progress['completedSessions']}',
                ),
                const SizedBox(height: 16),
                ProgressSummaryCard(
                  title: 'Study Time',
                  value: progress['studyTime'].toString(),
                ),
                const SizedBox(height: 16),
                ProgressSummaryCard(
                  title: 'Methods Used',
                  value: '${progress['methodsUsed']}',
                ),
                const SizedBox(height: 16),
                // Navigation back to home is handled by the bottom nav bar.
                // We show a motivational quote instead of a button.
                const QuoteCard(quote: 'Keep up the great work!'),
              ],
            ),
          );
        },
      ),
    );
  }
}