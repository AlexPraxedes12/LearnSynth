import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  const WideButton({super.key, required this.label, required this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label),
      ),
    );
  }
}
