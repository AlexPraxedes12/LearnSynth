class ModelFile {
  final String name;
  final int size;
  final String sha256;
  final String? url;
  final bool asset;
  final bool demo;

  ModelFile({
    required this.name,
    required this.size,
    required this.sha256,
    this.url,
    this.asset = false,
    this.demo = false,
  });

  factory ModelFile.fromJson(Map<String, dynamic> j) => ModelFile(
        name: j['name'],
        size: j['size'] ?? 0,
        sha256: j['sha256'],
        url: j['url'],
        asset: (j['asset'] ?? false) as bool,
        demo: (j['demo'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'size': size,
        'sha256': sha256,
        'url': url,
        'asset': asset,
        'demo': demo,
      };
}

class ModelManifest {
  final int ctxLen;
  final String tokenizer;
  final List<ModelFile> files;

  ModelManifest({required this.ctxLen, required this.tokenizer, required this.files});

  factory ModelManifest.fromJson(Map<String, dynamic> j) => ModelManifest(
        ctxLen: j['ctxLen'] ?? 2048,
        tokenizer: j['tokenizer'] ?? 'llama',
        files: (j['files'] as List)
            .map((e) => ModelFile.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'ctxLen': ctxLen,
        'tokenizer': tokenizer,
        'files': files.map((e) => e.toJson()).toList()
      };
}
