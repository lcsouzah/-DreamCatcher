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

/// Google OAuth Client ID for DreamCatcher (Google Fit integration)
const String kGoogleFitClientId =
    "890943023129-al2a6bq1n9l3em7abhsfi1pmvkg60o9p.apps.googleusercontent.com";