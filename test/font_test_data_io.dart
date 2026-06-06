import 'dart:io';
import 'dart:typed_data';

String? get systemFontFamily {
  if (Platform.isLinux) return 'DejaVu Sans';
  if (Platform.isMacOS || Platform.isWindows) return 'Arial';
  return null;
}

Future<Uint8List> loadTinosFontData() =>
    File('test/fonts/Tinos-Regular.ttf').readAsBytes();
