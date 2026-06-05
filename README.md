# usvg-dart

Dart bindings for [usvg](https://github.com/linebender/resvg/tree/main/crates/usvg)
using `flutter_rust_bridge` and Dart native-assets build hooks.

The Rust wrapper currently exposes SVG parsing, normalized SVG serialization,
image size, and empty-tree checks.

The build hook compiles and bundles the Rust library automatically when a
consumer runs, tests, or builds a Dart application. Consumers need `rustup`,
but do not need to manually build or locate the native library.

## Usage

```dart
await UsvgRustLib.init();

final tree = await SvgTree.parse(
  svg: '<svg width="10" height="20"><rect width="10" height="20"/></svg>',
);
print(tree.size);
print(await tree.toSvgString());
```

## Generate bindings

```shell
flutter_rust_bridge_codegen generate
```

## Build and test

```shell
dart test
```

The command invokes `hook/build.dart`, which builds the Rust crate for the
requested target and bundles it as a native asset. Consumer applications can
also use `dart run` and `dart build cli` without manually locating the library.

WebAssembly remains a separate `flutter_rust_bridge_codegen build-web` flow.

## Publishing

Generated Dart and Rust bridge files must be committed before publishing:

```shell
flutter_rust_bridge_codegen generate
dart pub publish --dry-run
dart pub publish
```
