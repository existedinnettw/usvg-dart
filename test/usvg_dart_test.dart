import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:usvg_dart/usvg_dart.dart';

import 'font_test_data.dart';

void main() {
  setUpAll(UsvgRustLib.init);
  tearDownAll(UsvgRustLib.dispose);

  test('parses and normalizes SVG', () async {
    final tree = SvgTree.parse(
      svg:
          '<svg width="10" height="20">'
          '<rect id="box" width="10" height="20"/>'
          '</svg>',
    );

    expect(tree.size, const SvgSize(width: 10, height: 20));
    expect(tree.isEmpty, isFalse);
    expect(tree.toSvgString(), contains('<path id="box"'));
  });

  test('reports parse errors', () async {
    expect(() => SvgTree.parse(svg: '<svg>'), throwsA(isA<String>()));
  });

  test('normalizes nested SVG elements', () async {
    final tree = SvgTree.parse(
      svg:
          '<svg width="100" height="100">'
          '<svg x="10" y="20" width="30" height="40">'
          '<rect width="30" height="40"/>'
          '</svg>'
          '</svg>',
    );

    final normalized = tree.toSvgString();
    expect(normalized, isNot(contains('<svg x=')));
    expect(normalized, contains('transform="matrix(1 0 0 1 10 20)"'));
  });

  test('normalizes text with system fonts', () {
    if (systemFontFamily == null) return;

    final tree = SvgTree.parse(
      svg:
          '<svg width="100" height="30">'
          '<text x="0" y="20" font-family="$systemFontFamily">Text</text>'
          '</svg>',
    );

    final normalized = tree.toSvgString();
    expect(normalized, contains('<path'));
    expect(normalized, isNot(contains('<text')));
  });

  test('preserves text during serialization when requested', () {
    if (systemFontFamily == null) return;

    final tree = SvgTree.parse(
      svg:
          '<svg width="100" height="30">'
          '<text x="0" y="20" font-family="$systemFontFamily">Text</text>'
          '</svg>',
    );

    final normalized = tree.toSvgString(preserveText: true);
    expect(normalized, contains('<text'));
    expect(normalized, contains('Text'));
  });

  test('preserves text loaded from caller-provided font data', () async {
    final font = await loadTinosFontData();
    if (font == null) return;

    const svg =
        '<svg width="100" height="30">'
        '<text x="0" y="20" font-family="Tinos">Tinos text</text>'
        '</svg>';

    final withoutFont = SvgTree.parse(
      svg: svg,
      options: _optionsWithFontData([]),
    ).toSvgString(preserveText: true);
    expect(withoutFont, isNot(contains('<text')));

    final withFont = SvgTree.parse(
      svg: svg,
      options: _optionsWithFontData([font]),
    ).toSvgString(preserveText: true);
    expect(withFont, contains('<text'));
    expect(withFont, contains('Tinos text'));
  });

  test('persistent font database reuses registered fonts', () async {
    final font = await loadTinosFontData();
    if (font == null) return;

    final database = UsvgFontDatabase(loadSystemFonts: false);
    expect(
      database.registerFontData(key: 'tinos-regular', data: font),
      greaterThan(0),
    );
    final faceCount = database.faceCount;
    expect(database.registerFontData(key: 'tinos-regular', data: font), 0);
    expect(database.faceCount, faceCount);

    const svg =
        '<svg width="100" height="30">'
        '<text x="0" y="20" font-family="Tinos">Tinos text</text>'
        '</svg>';
    final first = database
        .parse(svg: svg, options: _optionsWithFontData([]))
        .toSvgString(preserveText: true);
    final second = database
        .parse(svg: svg, options: _optionsWithFontData([]))
        .toSvgString(preserveText: true);

    expect(first, contains('<text'));
    expect(second, contains('<text'));
  });

  test('persistent font database rejects invalid font data', () {
    final database = UsvgFontDatabase(loadSystemFonts: false);
    expect(database.registerFontData(key: 'invalid', data: [1, 2, 3]), 0);
    expect(database.faceCount, 0);
  });
}

ParseOptions _optionsWithFontData(List<Uint8List> fontData) {
  final defaults = ParseOptions.default_();
  return ParseOptions(
    resourcesDir: defaults.resourcesDir,
    dpi: defaults.dpi,
    fontFamily: defaults.fontFamily,
    fontSize: defaults.fontSize,
    languages: defaults.languages,
    styleSheet: defaults.styleSheet,
    loadSystemFonts: false,
    fontData: fontData,
  );
}
