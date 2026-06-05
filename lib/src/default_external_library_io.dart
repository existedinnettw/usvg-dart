import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'native_asset_io.dart' as native_asset;

Future<ExternalLibrary?> load() async => native_asset.load();
