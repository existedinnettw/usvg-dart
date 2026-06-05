import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'default_external_library_stub.dart'
    if (dart.library.ffi) 'default_external_library_io.dart'
    if (dart.library.js_interop) 'default_external_library_web.dart'
    as default_external_library;
import 'rust/frb_generated.dart';

/// Manages the generated usvg Rust library used by this package.
final class UsvgRustLib {
  /// Initializes the native or WebAssembly usvg library.
  ///
  /// Applications must call this once before using [SvgTree].
  static Future<void> init({
    UsvgRustLibGeneratedApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
    bool forceSameCodegenVersion = true,
  }) async {
    await UsvgRustLibGenerated.init(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary ?? await default_external_library.load(),
      forceSameCodegenVersion: forceSameCodegenVersion,
    );
  }

  /// Initializes the library with a generated API mock for tests.
  static void initMock({required UsvgRustLibGeneratedApi api}) {
    UsvgRustLibGenerated.initMock(api: api);
  }

  /// Releases resources held by the generated usvg library.
  static void dispose() => UsvgRustLibGenerated.dispose();
}
