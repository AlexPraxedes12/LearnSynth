import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:learnsynth/services/offline_llm_compat.dart';
import '../core/util/offline_model_support.dart';
import '../config/env.dart';

const String kOfflineModelId = OfflineLLM.defaultModelId;

Future<int> _modelTotalBytes(String modelId) async {
  final s = await rootBundle.loadString(
    'packages/learnsynth_offline_llm/assets/models/$modelId/manifest.json',
  );
  final m = jsonDecode(s) as Map<String, dynamic>;
  final files = (m['files'] as List).cast<Map<String, dynamic>>();
  final total = files.fold<int>(0, (a, f) => a + ((f['size'] as int?) ?? 0));
  return total;
}

String _fmtBytes(int b) {
  const k = 1024.0;
  if (b < k) return '~$b B';
  final kb = b / k, mb = kb / k, gb = mb / k;
  if (gb >= 1) return '~${gb.toStringAsFixed(1)} GB';
  if (mb >= 1) return '~${mb.toStringAsFixed(1)} MB';
  return '~${kb.toStringAsFixed(1)} KB';
}

class OfflineSettingsSection extends StatefulWidget {
  const OfflineSettingsSection({super.key});

  @override
  State<OfflineSettingsSection> createState() => _OfflineSettingsSectionState();
}

class _OfflineSettingsSectionState extends State<OfflineSettingsSection> {
  @override
  void initState() {
    super.initState();
    if (Env.enableOfflineLLM) {
      () async {
        await OfflineLLM.instance.init(kOfflineModelId);
        final ready = OfflineLLM.instance.isReady;
        debugPrint('[OfflineLLM] modelId=$kOfflineModelId ready=$ready');
      }();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.enableOfflineLLM || !isOfflineModelSupported) {
      return const SizedBox.shrink();
    }
    final settings = context.watch<SettingsProvider>();
    final status = settings.offlineModelStatus;
    final installed = status == 'ready';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Usar LLM offline'),
          subtitle: const Text('Permite generar contenido sin internet'),
          value: settings.enableOfflineLLM,
          onChanged: (v) =>
              context.read<SettingsProvider>().setEnableOfflineLLM(v),
        ),
        ListTile(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _modelTotalBytes(kOfflineModelId),
                  builder: (context, snap) {
                    final label =
                        snap.hasData ? _fmtBytes(snap.data!) : '(...)';
                    return Text(
                      'Descargar modelo offline ($label)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (installed)
                const Icon(Icons.check_circle,
                    size: 18, color: Colors.green),
            ],
          ),
          subtitle: Text(
            switch (status) {
              'ready' => 'Instalado',
              'downloading' => 'Descargando...',
              'error' => 'Error: ${settings.offlineError ?? ""}',
              _ => 'No instalado',
            },
          ),
          trailing: switch (status) {
            'downloading' => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            'error' => const Icon(Icons.error, color: Colors.red),
            _ => const Icon(Icons.download),
          },
          onTap: (status == 'downloading' || installed)
              ? null
              : () async {
                  final sp = context.read<SettingsProvider>();
                  sp.setOfflineStatus('downloading');
                  try {
                    await OfflineLLM.instance.init(kOfflineModelId);
                    final ok = OfflineLLM.instance.isReady;
                    sp.setOfflineStatus(ok ? 'ready' : 'not_installed');
                  } catch (e) {
                    sp.setOfflineStatus('error', error: e.toString());
                  }
                },
        ),
        Row(
          children: [
            TextButton(
              onPressed: () async {
                await OfflineLLM.instance.init(kOfflineModelId);
                final ok = OfflineLLM.instance.isReady;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ok
                          ? 'SHA-256 OK'
                          : 'Verificación falló (hash no coincide o archivo ausente)')),
                );
                context
                    .read<SettingsProvider>()
                    .setOfflineStatus(ok ? 'ready' : 'not_installed');
              },
              child: const Text('Re-verificar'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await OfflineLLM.instance.init(kOfflineModelId);
                final ok = OfflineLLM.instance.isReady;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ok
                          ? 'Listo para usar'
                          : 'Modelo incompleto / no instalado')),
                );
                context
                    .read<SettingsProvider>()
                    .setOfflineStatus(ok ? 'ready' : 'not_installed');
              },
              child: const Text('Comprobar estado'),
            ),
            if (installed)
              TextButton.icon(
                onPressed: () async {
                  await OfflineLLM.instance.unload();
                  context
                      .read<SettingsProvider>()
                      .setOfflineStatus('not_installed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modelo eliminado')),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar modelo'),
              ),
          ],
        ),
      ],
    );
  }
}


