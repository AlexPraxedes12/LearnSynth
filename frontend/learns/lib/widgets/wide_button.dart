import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const WideButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor:
              enabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

