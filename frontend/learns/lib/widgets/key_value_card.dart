import 'package:flutter/material.dart';

/// A card that displays a map of key-value pairs.
class KeyValueCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const KeyValueCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: entry.value.toString()),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
