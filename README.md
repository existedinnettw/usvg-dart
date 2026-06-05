# usvg-dart

Dart bindings for [usvg](https://github.com/linebender/resvg/tree/main/crates/usvg)
using `flutter_rust_bridge`.

The Rust wrapper currently exposes SVG parsing, normalized SVG serialization,
image size, and empty-tree checks.

The Rust crate uses the local usvg source at `../resvg/crates/usvg`, relative to
this repository.

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

## Build the native library

```shell
cargo build --manifest-path rust/Cargo.toml --release
```

The generated loader looks for the native library in `rust/target/release/` by
default. Call `UsvgRustLib.init(externalLibrary: ...)` to supply a packaged
library from another location.
