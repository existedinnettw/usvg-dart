import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String? get systemFontFamily => null;

Future<Uint8List> loadTinosFontData() async {
  final url = Uri.base.resolve('fonts/Tinos-Regular.ttf').toString();
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Failed to load Tinos test font: ${response.status}');
  }

  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}
