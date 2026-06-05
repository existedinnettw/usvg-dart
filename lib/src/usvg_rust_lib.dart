import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'native_asset_stub.dart'
    if (dart.library.ffi) 'native_asset_io.dart'
    as native_asset;
import 'rust/frb_generated.dart';

final class UsvgRustLib {
  static Future<void> init({
    UsvgRustLibGeneratedApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
    bool forceSameCodegenVersion = true,
  }) async {
    await UsvgRustLibGenerated.init(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary ?? native_asset.load(),
      forceSameCodegenVersion: forceSameCodegenVersion,
    );
  }

  static void initMock({required UsvgRustLibGeneratedApi api}) {
    UsvgRustLibGenerated.initMock(api: api);
  }

  static void dispose() => UsvgRustLibGenerated.dispose();
}
