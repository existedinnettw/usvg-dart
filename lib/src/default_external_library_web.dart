import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import 'web_wasm_assets.dart';

const _wasmBindgenName = 'wasm_bindgen';
const _initializerName = '__usvg_dart_initialize_wasm';

Future<ExternalLibrary>? _initialization;
final _retainedScriptResources = <Object>[];

@visibleForTesting
Future<ExternalLibrary> Function()? embeddedWebWasmInitializerOverride;

Future<ExternalLibrary?> load() => initializeEmbeddedWebWasm();

Future<ExternalLibrary> initializeEmbeddedWebWasm() {
  return _initialization ??= _initializeAndClearOnFailure();
}

Future<ExternalLibrary> _initializeAndClearOnFailure() async {
  try {
    return await (embeddedWebWasmInitializerOverride?.call() ?? _initialize());
  } catch (_) {
    _initialization = null;
    rethrow;
  }
}

Future<ExternalLibrary> _initialize() async {
  final javascript =
      '${utf8.decode(base64Decode(embeddedWasmBindgenJavaScriptBase64))}\n'
      'globalThis.$_wasmBindgenName = $_wasmBindgenName;\n'
      'globalThis.$_initializerName = (bytes) => $_wasmBindgenName(bytes);\n';
  final blob = web.Blob(
    <web.BlobPart>[javascript.toJS].toJS,
    web.BlobPropertyBag(type: 'text/javascript'),
  );
  final blobUrl = web.URL.createObjectURL(blob);
  final script = web.HTMLScriptElement()..src = blobUrl;
  web.document.head!.append(script);

  try {
    await Future.any<void>([
      script.onLoad.first,
      script.onError.first.then<void>(
        (_) => throw StateError('Failed to load embedded wasm-bindgen script'),
      ),
    ]);

    final wasmBytes = base64Decode(embeddedWasmBinaryBase64);
    await _initializeWasm(wasmBytes.toJS).toDart;

    // FRB workers import this script URL after initialization.
    _retainedScriptResources.addAll([blobUrl, script]);
    // The analyzer resolves ExternalLibrary to its native conditional shape.
    // ignore: const_with_undefined_constructor_default
    return const ExternalLibrary(
      debugInfo: 'embedded wasm-bindgen JavaScript and WebAssembly',
      wasmBindgenName: _wasmBindgenName,
    );
  } catch (_) {
    script.remove();
    web.URL.revokeObjectURL(blobUrl);
    rethrow;
  }
}

@visibleForTesting
void resetEmbeddedWebWasmInitializerForTesting() {
  _initialization = null;
  embeddedWebWasmInitializerOverride = null;
}

@JS(_initializerName)
external JSPromise<JSAny?> _initializeWasm(JSUint8Array bytes);
