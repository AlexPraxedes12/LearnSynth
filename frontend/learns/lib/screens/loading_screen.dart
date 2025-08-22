import 'package:flutter/material.dart';
import '../widgets/quote_card.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Shows a loading state while content is being processed. Once the
/// processing is complete, the user can proceed to the analysis
/// screen. We use [Navigator.pushNamed] here rather than
/// [Navigator.pushReplacementNamed] so that the user can navigate
/// back if desired.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await context.read<ContentProvider>().runAnalysis();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed(Routes.studyPack);
      } else {
        final msg =
            context.read<ContentProvider>().lastError ?? 'Analyze failed.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.of(context).pop(); // go back so user can retry
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading')),
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
