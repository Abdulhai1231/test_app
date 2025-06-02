/// Firebase-Konfigurationsklasse für plattformspezifische Einstellungen
/// 
/// Enthält die notwendigen Konfigurationsdaten für Android und iOS
class FirebaseConfig {
  /// Konfiguration für Android-Plattform
  static const androidConfig = {
    "apiKey": "YOUR_ANDROID_API_KEY",          // API-Schlüssel für Android
    "appId": "YOUR_ANDROID_APP_ID",            // Firebase App-ID für Android
    "messagingSenderId": "YOUR_SENDER_ID",      // Sender-ID für Push-Nachrichten
    "projectId": "YOUR_PROJECT_ID",            // Firebase Projekt-ID
    "storageBucket": "YOUR_STORAGE_BUCKET",    // Cloud Storage Bucket
    "databaseURL": "YOUR_DATABASE_URL",        // Echtzeitdatenbank-URL
  };

  /// Konfiguration für iOS-Plattform
  static const iosConfig = {
    "apiKey": "YOUR_IOS_API_KEY",              // API-Schlüssel für iOS
    "appId": "YOUR_IOS_APP_ID",                // Firebase App-ID für iOS
    "messagingSenderId": "YOUR_SENDER_ID",     // Sender-ID für Push-Nachrichten
    "projectId": "YOUR_PROJECT_ID",            // Firebase Projekt-ID
    "storageBucket": "YOUR_STORAGE_BUCKET",    // Cloud Storage Bucket
    "databaseURL": "YOUR_DATABASE_URL",        // Echtzeitdatenbank-URL
    "iosClientId": "YOUR_IOS_CLIENT_ID",       // OAuth-Client-ID für iOS
    "iosBundleId": "YOUR_BUNDLE_ID",           // Bundle Identifier
  };
}