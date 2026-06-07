import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String? get systemFontFamily => null;

Future<Uint8List> loadTinosFontData() async {
  return _loadFont('Tinos-Regular.ttf');
}

Future<Uint8List> loadRobotoWoff2Data() => _loadFont('Roboto-Hello.woff2');

Future<Uint8List> _loadFont(String name) async {
  final url = Uri.base.resolve('fonts/$name').toString();
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Failed to load $name test font: ${response.status}');
  }

  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}
