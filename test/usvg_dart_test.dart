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

  test('normalizes text with caller-provided font data', () {
    final font = callerProvidedFontData;
    if (font == null) return;

    final defaults = ParseOptions.default_();
    final tree = SvgTree.parse(
      svg:
          '<svg width="100" height="30">'
          '<text x="0" y="20" font-family="DejaVu Sans">Text</text>'
          '</svg>',
      options: ParseOptions(
        resourcesDir: defaults.resourcesDir,
        dpi: defaults.dpi,
        fontFamily: defaults.fontFamily,
        fontSize: defaults.fontSize,
        languages: defaults.languages,
        styleSheet: defaults.styleSheet,
        loadSystemFonts: false,
        fontData: [font],
      ),
    );

    final normalized = tree.toSvgString();
    expect(normalized, contains('<path'));
    expect(normalized, isNot(contains('<text')));
  });
}
