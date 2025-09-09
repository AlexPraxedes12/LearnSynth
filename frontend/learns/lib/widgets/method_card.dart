import 'package:flutter/material.dart';

/// A card used on the method selection screen. Shows an icon,
/// a title and description. On tap it executes a callback. Based on
/// upstream implementation.
class MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? summary;
  final VoidCallback onTap;

  const MethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceVariant,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                    ),
                    if (summary != null && summary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        summary!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
