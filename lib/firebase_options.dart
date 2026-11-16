// Emulator-only placeholder configuration.
//
// These values point at the local "demo-cloud-quest" project used by the
// Firebase Emulator Suite. They are not secrets and reach no real project.
// To use the course Firebase project instead, run from the project root:
//   flutterfire configure --project=<course-project-id> --platforms=android
// which overwrites this file, then run the app with
//   flutter run --dart-define=USE_EMULATORS=false
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => demo;

  static const FirebaseOptions demo = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-cloud-quest',
  );
}
