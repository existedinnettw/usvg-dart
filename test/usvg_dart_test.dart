import 'package:test/test.dart';
import 'package:usvg_dart/usvg_dart.dart';

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
}
