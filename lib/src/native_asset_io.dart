import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

@Native<Pointer<Utf8> Function()>(symbol: 'usvg_dart_library_path')
external Pointer<Utf8> _libraryPath();

ExternalLibrary load() {
  final path = _libraryPath().toDartString();
  if (Platform.isIOS || path == Platform.resolvedExecutable) {
    return ExternalLibrary.process(iKnowHowToUseIt: true);
  }
  return ExternalLibrary.open(path);
}
