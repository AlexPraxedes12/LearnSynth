class File {
  final String path;
  File(this.path);
  Future<int> length() async => 0;
  int lengthSync() => 0;
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<void> delete() async {}
}

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Stream<dynamic> list({bool followLinks = false}) => const Stream.empty();
  Future<void> create({bool recursive = false}) async {}
}

const kModelsFolderName = 'models';
const kPreferredNames = <String>[];

Future<String> getModelsDirectory() async => '';

Future<Directory> getModelsDir() async => Directory('');

Future<File?> pickInstalledModel({List<String> preferred = kPreferredNames}) async => null;

String humanSize(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

