import 'dart:io';
import 'dart:typed_data';

String? get systemFontFamily {
  if (Platform.isLinux) return 'DejaVu Sans';
  if (Platform.isMacOS || Platform.isWindows) return 'Arial';
  return null;
}

Uint8List? get callerProvidedFontData {
  if (!Platform.isLinux) return null;

  return File(
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ).readAsBytesSync();
}
