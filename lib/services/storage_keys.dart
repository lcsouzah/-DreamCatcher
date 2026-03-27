class StorageKeys {
  const StorageKeys._();

  static const String onboardingComplete = 'hasCompletedOnboarding';
  static const String cachedSleepEntries = 'cachedSleepEntries';
  static const String cachedSleepRecords = 'cachedSleepRecords';
  static const String enableNotifications = 'enableNotifications';
  static const String darkModeAccentIntensity = 'darkModeAccentIntensity';
  static const String healthConnectAutoSync = 'healthConnectAutoSync';
  static const String enableSupabase = 'enableSupabase';
  static const String enableDebugLogging = 'enableDebugLogging';
  static const String useMockData = 'useMockData';
}

/// DreamCatcher WEB OAuth client ID (server client ID) used by Android Google Sign-In.
///
/// Preferred source:
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
///
/// Backward compatibility:
///   --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  ),
);