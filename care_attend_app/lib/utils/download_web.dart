// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Trigger a browser download of text content (CSV/JSON) on Flutter web.
void downloadText(String filename, String text, String mime) {
  final blob = html.Blob([text], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
