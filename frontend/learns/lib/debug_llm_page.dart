import 'package:flutter/material.dart';
import 'core/llm/llm_service.dart';

class DebugLlmPage extends StatefulWidget {
  const DebugLlmPage({super.key});

  @override
  State<DebugLlmPage> createState() => _DebugLlmPageState();
}

class _DebugLlmPageState extends State<DebugLlmPage> {
  final _promptCtrl = TextEditingController(text: 'Hola, ¿quién eres?');
  final _outCtrl = TextEditingController();
  final _svc = LlmService.I;

  Future<void> _gen() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    _outCtrl.clear();
    try {
      final out = await _svc.generate(prompt, maxTokens: 64);
      _outCtrl.text = out;
    } catch (e) {
      _outCtrl.text = 'ERROR: $e';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _svc,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Debug LLM')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Modo: ${_svc.mode}'),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptCtrl,
                  decoration: const InputDecoration(labelText: 'Prompt'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _svc.busy ? null : _gen,
                  child: _svc.busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generar'),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _outCtrl,
                    readOnly: true,
                    maxLines: null,
                    decoration: const InputDecoration(labelText: 'Output'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
