import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Must be called in `setUpAll` (or top-level `main`) before any widget that
/// uses google_fonts is pumped.
///
/// 1. Disables runtime font fetching so google_fonts never hits the network.
/// 2. Installs a mock handler on the `flutter/assets` binary messaging channel
///    that serves font `.ttf` files from the project's `assets/fonts/`
///    directory, while delegating all other asset requests to the standard
///    test asset directory (`build/unit_test_assets`).
void setupGoogleFontsForTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Pre-read all font files from the project root into memory.
  final Map<String, ByteData> fontCache = {};
  final fontDir = Directory('assets/fonts');
  if (fontDir.existsSync()) {
    for (final file in fontDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.ttf')) continue;
      final bytes = file.readAsBytesSync();
      fontCache[file.path] = ByteData.sublistView(Uint8List.fromList(bytes));
    }
  }

  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (ByteData? message) async {
      if (message == null) return null;

      // PlatformAssetBundle URI-encodes the key before sending; decode it back.
      final raw = utf8.decode(
        message.buffer
            .asUint8List(message.offsetInBytes, message.lengthInBytes),
      );
      final key = Uri.decodeFull(raw);

      // Serve bundled font files from the project root.
      if (fontCache.containsKey(key)) {
        return fontCache[key];
      }

      // For everything else, read from the standard test-asset build output.
      final testAssetFile = File('build/unit_test_assets/$key');
      if (testAssetFile.existsSync()) {
        final bytes = testAssetFile.readAsBytesSync();
        return ByteData.sublistView(Uint8List.fromList(bytes));
      }

      // Asset not found — return null (PlatformAssetBundle will throw).
      return null;
    },
  );
}
