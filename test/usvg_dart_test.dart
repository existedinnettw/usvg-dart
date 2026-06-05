import 'package:test/test.dart';
import 'package:usvg_dart/usvg_dart.dart';

void main() {
  setUpAll(UsvgRustLib.init);
  tearDownAll(UsvgRustLib.dispose);

  test('parses and normalizes SVG', () async {
    final tree = await SvgTree.parse(
      svg:
          '<svg width="10" height="20">'
          '<rect id="box" width="10" height="20"/>'
          '</svg>',
    );

    expect(tree.size, const SvgSize(width: 10, height: 20));
    expect(tree.isEmpty, isFalse);
    expect(await tree.toSvgString(), contains('<path id="box"'));
  });

  test('reports parse errors', () async {
    expect(SvgTree.parse(svg: '<svg>'), throwsA(isA<String>()));
  });
}
