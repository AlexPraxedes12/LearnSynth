// Selecciona implementación en tiempo de compilación.
export 'model_download_io.dart'
  if (dart.library.html) 'model_download_stub.dart';

