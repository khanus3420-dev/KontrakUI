class AppConfig {
  AppConfig._();

  // Provide these via --dart-define at build / run time.
  // Defaults are provided so `flutter run` works without extra flags.
  // Override via --dart-define in CI/production if needed.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kontrakapi.onrender.com',
  );
}
