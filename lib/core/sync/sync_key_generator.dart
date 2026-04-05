import 'dart:math';

/// Generates stable sync keys for locally-created entities before they get a
/// durable cloud identity.
class SyncKeyGenerator {
  SyncKeyGenerator._();

  /// Example: `tx_1712345678901_a3f2`
  static String generate(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random.secure()
        .nextInt(0x10000)
        .toRadixString(16)
        .padLeft(4, '0');
    return '${prefix}_${ts}_$rand';
  }
}
