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
- The browser's Content Security Policy must permit `blob:` scripts and worker
  imports.
- Worker-backed asynchronous calls require cross-origin isolation, normally
  configured with `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp`.

The wasm-bindgen JavaScript blob URL is intentionally retained after startup
because Flutter Rust Bridge workers load it with `importScripts`.

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
4. Preserve initialization caching, explicit load errors, retries, and worker
   support.
5. Keep `UsvgRustLib.init()` and explicit `externalLibrary` behavior unchanged.
6. Verify plain Dart web, Flutter web, native tests, publication contents, CSP,
   and worker-backed asynchronous calls.
