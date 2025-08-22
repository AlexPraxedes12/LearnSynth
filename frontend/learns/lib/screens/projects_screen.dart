import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays the list of saved study content. Replaces the old
/// [LibraryScreen] which was an empty placeholder.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: items.isEmpty
            ? const Center(
                child: Text('No content yet',
                    style: TextStyle(color: Colors.white70)),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final title = items[index];
                  return Card(
                    color: AppTheme.accentGray,
                    child: ListTile(
                      title: Text(title,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
