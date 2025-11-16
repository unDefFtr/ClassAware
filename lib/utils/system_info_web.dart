import 'dart:html' as html;

String getSystemVersion() {
  final ua = html.window.navigator.userAgent;
  return ua;
}