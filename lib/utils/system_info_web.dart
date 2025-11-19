import 'dart:html' as html;

String getSystemVersion() {
  final ua = html.window.navigator.userAgent;
  String pick(String marker) {
    final i = ua.indexOf(marker);
    if (i == -1) return '';
    final start = i + marker.length;
    final end = ua.indexOf(' ', start);
    return (end == -1 ? ua.substring(start) : ua.substring(start, end)).trim();
  }
  if (ua.contains('Edg/')) {
    final v = pick('Edg/');
    return 'Edge $v';
  }
  if (ua.contains('OPR/')) {
    final v = pick('OPR/');
    return 'Opera $v';
  }
  if (ua.contains('Firefox/')) {
    final v = pick('Firefox/');
    return 'Firefox $v';
  }
  if (ua.contains('Chrome/')) {
    final v = pick('Chrome/');
    return 'Chrome $v';
  }
  if (ua.contains('Version/') && ua.contains('Safari/')) {
    final v = pick('Version/');
    return 'Safari $v';
  }
  return ua;
}