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
/// This is used as the serverClientId in GoogleSignIn.initialize.
/// 
/// The source is now centralized in the .env file.
const String kGoogleServerClientId = '84818727473-dp55em8h0mfsjlsp63m4cqnrbuguuipc.apps.googleusercontent.com';
