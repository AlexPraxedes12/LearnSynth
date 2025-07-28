import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const MethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.accentGray,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accentTeal),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
