import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import '../theme/app_theme.dart';

/// Displays the list of saved study content. Replaces the old
/// [LibraryScreen] which was an empty placeholder.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final items = provider.savedContent;
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
                  final item = items[index];
                  final title = item.filePath != null
                      ? item.filePath!.split(RegExp(r'[\\/]')).last
                      : item.text?.split('\n').first.trim() ?? 'Untitled';
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
