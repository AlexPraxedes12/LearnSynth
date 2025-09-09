import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> exportPackImpl(Uint8List data, String fileName) async {
  final blob = html.Blob([data], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}
