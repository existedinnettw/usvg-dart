@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:test/test.dart';
import 'package:usvg_dart/src/default_external_library_web.dart';
import 'package:web/web.dart' as web;

void main() {
  tearDown(resetEmbeddedWebWasmInitializerForTesting);

  test(
    'initializes the embedded WebAssembly without deployed assets',
    () async {
      expect(web.window.crossOriginIsolated, isFalse);
      final library = await initializeEmbeddedWebWasm();
      expect(library.debugInfo, contains('embedded wasm-bindgen'));
    },
  );

  test('concurrent initialization shares one future', () async {
    final completer = Completer<ExternalLibrary>();
    var calls = 0;
    embeddedWebWasmInitializerOverride = () {
      calls++;
      return completer.future;
    };

    final first = initializeEmbeddedWebWasm();
    final second = initializeEmbeddedWebWasm();
    expect(identical(first, second), isTrue);

    // The analyzer resolves ExternalLibrary to its native conditional shape.
    // ignore: const_with_undefined_constructor_default
    completer.complete(const ExternalLibrary(debugInfo: 'test'));
    await Future.wait([first, second]);
    expect(calls, 1);
  });

  test('failed initialization completes and permits retry', () async {
    var calls = 0;
    embeddedWebWasmInitializerOverride = () async {
      calls++;
      if (calls == 1) throw StateError('expected failure');
      // ignore: const_with_undefined_constructor_default
      return const ExternalLibrary(debugInfo: 'test');
    };

    await expectLater(initializeEmbeddedWebWasm(), throwsStateError);
    await initializeEmbeddedWebWasm();
    expect(calls, 2);
  });
}
