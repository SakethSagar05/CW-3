#!/usr/bin/env bash
# One-time setup. Run from anywhere:  bash tools/setup.sh
# Adds the Android platform folder, fetches packages and installs the
# Functions dependencies. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/env.sh
need flutter "Install the Flutter SDK or open a terminal where 'flutter --version' works."
need npm "Install Node.js 22."
need firebase "Run: npm install -g firebase-tools"

if [ ! -d android ]; then
  echo "==> Adding the Android platform"
  # Keep the hand-written files safe in case flutter create replaces any.
  BACKUP="$(mktemp -d)"
  cp -R lib test README.md pubspec.yaml .gitignore analysis_options.yaml "$BACKUP"/
  flutter create . --platforms=android --project-name cloud_quest --org edu.gsu.csc4360
  cp -R "$BACKUP"/lib "$BACKUP"/test .
  cp "$BACKUP"/README.md "$BACKUP"/pubspec.yaml "$BACKUP"/.gitignore "$BACKUP"/analysis_options.yaml .
else
  echo "==> android/ already exists, skipping flutter create"
fi

echo "==> Pinning Firestore and Functions packages to versions that match firebase_core"
flutter pub add cloud_firestore cloud_functions || true
flutter pub get

GRADLE=android/app/build.gradle.kts
if [ -f "$GRADLE" ] && ! grep -q "maxOf(flutter.minSdkVersion, 23)" "$GRADLE"; then
  echo "==> Setting Android minSdk to at least 23 (required by Firebase)"
  perl -pi -e 's/minSdk\s*=\s*flutter\.minSdkVersion/minSdk = maxOf(flutter.minSdkVersion, 23)/' "$GRADLE"
fi

echo "==> Allowing plain HTTP in DEBUG builds only, so the app can reach the local emulators"
mkdir -p android/app/src/debug
cat > android/app/src/debug/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Debug only: the Firebase emulators on 10.0.2.2 speak plain HTTP. -->
    <application android:usesCleartextTraffic="true"/>
</manifest>
XML

echo "==> Installing Cloud Functions dependencies"
(cd functions && npm install)

echo
echo "Setup finished. Next:"
echo "  1. bash tools/start_emulators.sh        (terminal 1, leave running)"
echo "  2. flutter run                          (terminal 2, Android emulator open)"
