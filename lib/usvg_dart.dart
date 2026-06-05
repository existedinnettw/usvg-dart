/// Dart bindings for parsing and normalizing SVG with usvg.
///
/// Use [SvgTree.parse] to resolve complex SVG features into a simpler SVG
/// representation that downstream Dart and Flutter renderers can consume.
library;

export 'src/rust/api.dart';
export 'src/usvg_rust_lib.dart' show UsvgRustLib;
