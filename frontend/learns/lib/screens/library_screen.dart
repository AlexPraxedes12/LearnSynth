import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';
import '../services/export_service.dart';

bool validatePackStructure(Map<String, dynamic> pack) {
  return pack.containsKey('id') &&
      pack['id'].toString().isNotEmpty &&
      pack.containsKey('createdAt');
}

Future<void> _showLoadingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final box = Hive.box<Map>('learnpacks');
    final cp = context.watch<ContentProvider>();
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (_, __, ___) {
        final packs = cp.listPacks();

        return Scaffold(
          appBar: AppBar(
            title: Text(app.library),
            actions: [
              IconButton(
                tooltip: app.importJson,
                icon: const Icon(Icons.file_open),
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (res == null || res.files.isEmpty) return;
                  _showLoadingDialog(context);
                  try {
                    final f = res.files.first;
                    final bytes =
                        f.bytes ?? await File(f.path!).readAsBytes();
                    final pack = jsonDecode(utf8.decode(bytes))
                        as Map<String, dynamic>;
                    if (!validatePackStructure(pack)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid pack file'),
                          ),
                        );
                      }
                      return;
                    }
                    final id = pack['id'].toString();
                    await box.put(id, Map<String, dynamic>.from(pack));
                    await context.read<ContentProvider>().refreshPacks();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Import successful'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Import failed'),
                        ),
                      );
                    }
                  } finally {
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }
                },
              ),
              const SettingsButton(),
            ],
          ),
          body: packs.isEmpty
              ? Center(child: Text(app.noContentYet))
              : ListView.separated(
                  itemCount: packs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = packs[i];
                    final id = (p['id'] ?? '').toString();
                    final title = cp.getPackDisplayName(id);
                    final date = (p['createdAt'] ?? '').toString();
                    final prog = double.tryParse(
                      p['progress']?.toString() ?? '',
                    );
                    return ListTile(
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date),
                          if (prog != null)
                            LinearProgressIndicator(value: prog / 100),
                        ],
                      ),
                      onTap: () async {
                        final cp = context.read<ContentProvider>();
                        await cp.hydrateFromPack(p);
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, Routes.studyPack);
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'export') {
                            final data = utf8.encode(jsonEncode(p));
                            final fileName =
                                '${title.replaceAll(' ', '_')}_${DateTime.now().toIso8601String().split('T').first}.json';
                            _showLoadingDialog(context);
                            try {
                              final path = await exportPack(
                                Uint8List.fromList(data),
                                fileName,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(app.exportedTo(path ?? fileName)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Export failed'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop();
                              }
                            }
                          } else if (v == 'delete') {
                            final confirmed =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(app.deletePackQuestion),
                                    content: Text(app.deletePackWarning),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(app.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(app.delete),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (confirmed) {
                              await box.delete(id);
                            }
                          } else if (v == 'rename') {
                            final controller = TextEditingController(text: title);
                            final newTitle = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(app.renameCourse),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(app.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final val = controller.text.trim();
                                      if (val.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(app.nameCannotBeEmpty),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.pop(ctx, val);
                                    },
                                    child: Text(app.save),
                                  ),
                                ],
                              ),
                            );
                            if (newTitle != null && newTitle != title) {
                              final updated = Map<String, dynamic>.from(p);
                              updated['title'] = newTitle;
                              updated['customName'] = newTitle;
                              await box.put(id, updated);
                              await context
                                  .read<ContentProvider>()
                                  .refreshPacks();
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(app.rename),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Text(app.export),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(app.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
