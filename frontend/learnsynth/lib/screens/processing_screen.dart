import 'package:flutter/material.dart';
import '../widgets/quote_card.dart';
import '../constants.dart';

/// Shows a loading state while content is being processed. Once the
/// processing is complete, the user can proceed to the analysis
/// screen. We use [Navigator.pushNamed] here rather than
/// [Navigator.pushReplacementNamed] so that the user can navigate
/// back if desired.
class ProcessingScreen extends StatefulWidget {
  final String? text;
  const ProcessingScreen({super.key, this.text});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushNamed(
          context,
          Routes.analysis,
          arguments: widget.text,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            QuoteCard(quote: 'Learning never exhausts the mind.'),
          ],
        ),
      ),
    );
  }
}
