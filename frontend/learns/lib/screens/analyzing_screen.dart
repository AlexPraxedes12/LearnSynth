import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});
  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final provider = context.read<ContentProvider>();
    final ok = await provider.runAnalysis();
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacementNamed(Routes.studyPack);
    } else {
      final msg = (provider.lastError?.isNotEmpty ?? false)
          ? provider.lastError!
          : 'Analyze failed. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Analyzing')),
      body: Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(height: 44, child: Center(child: Text('Analyzing...'))),
      ),
    );
  }
}
