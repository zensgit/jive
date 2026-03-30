/// Supabase project configuration.
///
/// These values come from Supabase Dashboard → Settings → API.
/// For local dev / CI, override via --dart-define or .env.
class SyncConfig {
  SyncConfig._();

  /// Supabase project URL.
  /// Override with: --dart-define=SUPABASE_URL=https://xxx.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anon (public) key.
  /// Override with: --dart-define=SUPABASE_ANON_KEY=xxx
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Whether Supabase credentials are configured.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
