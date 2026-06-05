import 'package:usvg_dart/usvg_dart.dart';

Future<void> main() async {
  await UsvgRustLib.init();
  final tree = await SvgTree.parse(
    svg: '<svg width="10" height="20"><rect width="10" height="20"/></svg>',
  );
  print('${tree.size.width} x ${tree.size.height}');
}
