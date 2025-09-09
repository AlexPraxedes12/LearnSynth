import 'package:flutter/material.dart';
import 'package:learnsynth_offline_llm/learnsynth_offline_llm.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _llm = LearnsynthOfflineLlm.instance;
  final _userCtrl = TextEditingController();
  final _sysCtrl = TextEditingController(
      text: 'Responde SIEMPRE en español neutro.');

  double _temp = 0.6;
  double _topP = 0.9;
  double _topK = 40;
  double _repeatPenalty = 1.10;
  double _repeatLastN = 64;
  double _seed = 1234;

  String _out = '';

  Future<void> _run() async {
    final text = await _llm.generate(
      _userCtrl.text,
      systemPrompt: _sysCtrl.text.isEmpty ? null : _sysCtrl.text,
      temperature: _temp,
      topP: _topP,
      topK: _topK.toInt(),
      repeatPenalty: _repeatPenalty,
      repeatLastN: _repeatLastN.toInt(),
      seed: _seed.toInt(),
    );
    setState(() {
      _out = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Offline LLM')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _sysCtrl,
                decoration:
                    const InputDecoration(labelText: 'System prompt (opcional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 16),
              _buildSlider('Temp', _temp, 0.0, 2.0, (v) => setState(() => _temp = v)),
              _buildSlider('Top P', _topP, 0.0, 1.0, (v) => setState(() => _topP = v)),
              _buildSlider('Top K', _topK, 0, 100,
                  (v) => setState(() => _topK = v)),
              _buildSlider('Repeat penalty', _repeatPenalty, 1.0, 2.0,
                  (v) => setState(() => _repeatPenalty = v)),
              _buildSlider('Repeat last N', _repeatLastN, 0, 256,
                  (v) => setState(() => _repeatLastN = v)),
              _buildSlider('Seed', _seed, 0, 10000,
                  (v) => setState(() => _seed = v)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _run, child: const Text('Generar')),
              const SizedBox(height: 16),
              Text(_out),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label: ${value.toStringAsFixed(2)}'),
              Slider(value: value, min: min, max: max, onChanged: onChanged),
            ],
          ),
        ),
      ],
    );
  }
}
