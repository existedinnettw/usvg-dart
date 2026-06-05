# usvg-dart

Dart bindings for [usvg](https://github.com/linebender/resvg/tree/main/crates/usvg)
that normalize complex, standards-compliant SVG into a simpler representation
before it reaches a Dart or Flutter renderer.

SVG support in packages such as `flutter_svg`, `jovial_svg`, and `pdf` is
necessarily limited. Features such as nested `<svg>` elements may not render as
expected. `usvg_dart` resolves and flattens these features first, producing SVG
that is easier for downstream packages to parse and render consistently.

The package exposes SVG parsing, normalized SVG serialization, image size, and
empty-tree checks through `flutter_rust_bridge`.

The build hook compiles and bundles the Rust library automatically when a
consumer runs, tests, or builds a Dart application. Consumers need `rustup`,
but do not need to manually build or locate the native library.

## Usage

```dart
await UsvgRustLib.init();

final tree = SvgTree.parse(
  svg: '<svg width="10" height="20"><rect width="10" height="20"/></svg>',
);
print(tree.size);
print(tree.toSvgString());
```

The serialized result can then be passed to the SVG renderer used by your
application.

## Supported platforms

`usvg_dart` supports Android, iOS, Linux, macOS, Windows, and web. Native
platforms use Dart native-assets build hooks. Web uses embedded WebAssembly
assets, so consumers do not need an asset copy step.

## Requirements

The build hook compiles and bundles the Rust library automatically when a
consumer runs, tests, or builds a Dart application. Consumers need `rustup`,
but do not need to manually build or locate the native library.

Web consumers require no asset copy step. The generated wasm-bindgen JavaScript
and WASM binary are embedded in the package; see
[Embedded WebAssembly assets](doc/web-wasm-assets.md) for tradeoffs and browser
requirements. Web calls run synchronously and do not require cross-origin
isolation or `SharedArrayBuffer`.

## Development

```shell
flutter_rust_bridge_codegen generate
dart test
```

## Publishing

Generated Dart and Rust bridge files must be committed before publishing:

```shell
flutter_rust_bridge_codegen generate
dart pub publish --dry-run
dart pub publish
```
