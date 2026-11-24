/// Runtime configuration for the mobile application.
class ApiConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vdqdithxujxvzyybjtpn.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcWRpdGh4dWp4dnp5eWJqdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMzA2NTIsImV4cCI6MjEwODgwNjY1Mn0.7zE0gLxh0a2DNzdVcRfTj3EZDaqXWZ09kL5gcXTETXY',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_9-reGMqpk71zyWtbiBvOQA_kjQ9sbmS',
  );

  /// Service role key & backend secrets must NEVER be hardcoded into the client app.
  /// Privileged operations must be executed in secure backend environments
  /// (e.g. Supabase Edge Functions / Admin servers) where keys are kept in environment variables.
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '',
  );

  static const String supabaseApiSecretKey = String.fromEnvironment(
    'SUPABASE_SECRET_KEY',
    defaultValue: '',
  );

  /// Callback redirect URL untuk Google OAuth via Supabase:
  /// - Pada Android Native: mampir://auth-callback (dapat dioverride via AUTH_CALLBACK_URL)
  /// - Pada Web: menggunakan runtime browser origin (Uri.base.origin)
  static const String androidAuthCallback = String.fromEnvironment(
    'AUTH_CALLBACK_URL',
    defaultValue: 'mampir://auth-callback',
  );

  // Google Maps API Keys.
  //
  // Jangan hardcode key di source code. Suntikkan saat build/run:
  //   flutter run \
  //     --dart-define=GOOGLE_PLACES_API_KEY=... \
  //     --dart-define=GOOGLE_ROUTES_API_KEY=...
  //
  // GOOGLE_MAPS_API_KEY untuk Android Maps SDK diatur lewat
  // android/gradle.properties (manifestPlaceholder), bukan lewat Dart.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  static const String googleRoutesApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
  );

  static String get placesEndpoint {
    final clean = supabaseUrl.endsWith('/')
        ? supabaseUrl.substring(0, supabaseUrl.length - 1)
        : supabaseUrl;
    return clean.endsWith('/rest/v1')
        ? '$clean/places'
        : '$clean/rest/v1/places';
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get isGoogleConfigured =>
      googlePlacesApiKey.isNotEmpty && googleRoutesApiKey.isNotEmpty;

  static Map<String, String> get headers {
    final authorization = ['Bearer', supabaseAnonKey].join(' ');
    return {
      'apikey': supabaseAnonKey,
      'Authorization': authorization,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }
}
