import 'dart:io';

String getSystemVersion() {
  try {
    return Platform.operatingSystemVersion;
  } catch (_) {
    return '未知';
  }
}