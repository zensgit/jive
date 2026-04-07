import 'package:uuid/uuid.dart';

/// Generates stable sync keys for locally-created entities before they get a
/// durable cloud identity.
class SyncKeyGenerator {
  SyncKeyGenerator._();

  static const Uuid _uuid = Uuid();

  /// Example: `tx_550e8400-e29b-41d4-a716-446655440000`
  static String generate(String prefix) {
    return '${prefix}_${_uuid.v4()}';
  }

  /// Generates a deterministic UUIDv5-based key from a stable seed.
  static String generateDeterministic(String prefix, String seed) {
    return '${prefix}_${_uuid.v5(Namespace.url.value, seed)}';
  }
}
