## Unreleased

- Add `preserveText` to `SvgTree.toSvgString()` for serializing parsed text as
  SVG text elements instead of paths.
- Add a persistent `UsvgFontDatabase` for registering dynamic font bytes once
  and reusing them across SVG parses.

## 1.0.2

- Remove the web cross-origin isolation and `SharedArrayBuffer` requirement.
- Run web SVG operations synchronously on the browser main thread.

## 1.0.1

- Embed web WebAssembly assets for zero-setup browser initialization.
- Improve package metadata and public API documentation.
- Document and test nested SVG normalization.

## 1.0.0

- Add flutter_rust_bridge bindings for local usvg.
- Support SVG parsing, normalized serialization, size, and empty-tree queries.
