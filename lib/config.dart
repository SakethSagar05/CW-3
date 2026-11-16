import 'package:flutter/foundation.dart';

/// On by default because the bundled options are the emulator demo project.
/// Turn off with: flutter run --dart-define=USE_EMULATORS=false
const bool useEmulators =
    bool.fromEnvironment('USE_EMULATORS', defaultValue: true);

/// For a physical device, pass the computer's LAN address:
///   flutter run --dart-define=EMULATOR_HOST=192.168.1.20
const String emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

const String functionsRegion = 'us-central1';

String get emulatorHost {
  if (emulatorHostOverride.isNotEmpty) return emulatorHostOverride;
  // The Android emulator reaches the computer through 10.0.2.2;
  // the iOS simulator shares the computer's localhost.
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
}
