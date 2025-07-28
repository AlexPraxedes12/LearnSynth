import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays a motivational quote in a colored card. Copied from the
/// upstream repository to maintain consistent styling.
class QuoteCard extends StatelessWidget {
  final String quote;
  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.accentGray,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          quote,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}