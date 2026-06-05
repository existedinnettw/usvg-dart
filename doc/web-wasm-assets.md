# Embedded WebAssembly assets

Plain Dart web package publication does not deploy files from a dependency's
`web/` directory into the consuming application's output. Requiring every
consumer to copy the generated wasm-bindgen JavaScript and WASM binary would
make web support dependent on application-specific build configuration.

`usvg_dart` therefore publishes both generated artifacts as chunked base64
constants in `lib/src/web_wasm_assets.dart`. `UsvgRustLib.init()` decodes and
initializes them in the browser unless the caller supplies an
`externalLibrary`. The generated `web/pkg` directory remains temporary build
output and is not published.

## Costs and browser requirements

- Base64 adds approximately 33% encoded-size overhead and increases compiled
  JavaScript size.
- Startup must decode both embedded artifacts.
- The WASM binary cannot be cached independently from the application.
- The browser's Content Security Policy must permit `blob:` scripts during
  initialization.

## Main-thread WebAssembly

Web calls run synchronously on the browser's main thread. Every exported Rust
operation is marked `#[frb(sync)]`, so Flutter Rust Bridge does not dispatch
calls to its Web Worker pool or share WebAssembly memory between workers. The
web build also deliberately avoids WebAssembly atomic target features.

Flutter Rust Bridge 2.12.0's generated web default handler does not compile
when its `thread-pool` Cargo feature is disabled. The feature therefore remains
compiled as an internal dependency, but no exported operation uses it.

This keeps deployment compatible with ordinary static hosting. Consumers do
not need `Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy`,
`crossOriginIsolated`, or `SharedArrayBuffer`.

The tradeoff is that parsing or serializing a sufficiently large SVG can block
the browser UI until the call returns. If that becomes a practical problem,
worker execution should be added as an optional integration rather than making
cross-origin isolation mandatory for all consumers.

Release builds disable `wasm-opt` because its current extern-reference
optimization produces a fixed-size table that fails during wasm-bindgen
initialization in Chrome.

## Future `data_assets` migration

Migrate when Dart and Flutter provide stable web support for `data_assets`, a
standard runtime URL for package data assets, and consistent behavior across
the tested plain Dart and Flutter web build pipelines.

Migration checklist:

1. Publish the JavaScript and WASM binary as binary data assets.
2. Replace the embedded constants and generator with runtime asset URL lookup.
3. Load wasm-bindgen JavaScript and WASM from those URLs.
4. Preserve initialization caching, explicit load errors, and retries.
5. Keep `UsvgRustLib.init()` and explicit `externalLibrary` behavior unchanged.
6. Verify plain Dart web, Flutter web, native tests, publication contents, CSP,
   and synchronous web calls without cross-origin isolation.
