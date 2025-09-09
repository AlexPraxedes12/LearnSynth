// Implementación “vacía” para Web: no descarga, evita imports nativos.

class ModelInfo {
  final String id;
  final String name;
  final int sizeBytes;
  final String sha256;
  final List<Uri> mirrors;
  const ModelInfo({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.sha256,
    required this.mirrors,
  });
}

class ModelCatalog {
  // Mantener simple en Web (podríamos listar, pero no es necesario).
  Future<List<ModelInfo>> fetch() async => const <ModelInfo>[];
}

class ModelDownloader {
  Future<dynamic /*File?*/ > downloadModel({
    required String filename,
    required List<Uri> mirrors,
    required String expectedSha256,
    required int expectedSize,
    void Function(double p)? onProgress,
  }) async => null;

  static Future<String> modelsDirPath() async => '(no disponible en Web)';
}

